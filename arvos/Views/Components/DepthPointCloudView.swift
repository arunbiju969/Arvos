//
//  DepthPointCloudView.swift
//  arvos
//
//  High-performance ARKit depth point cloud visualization using Metal
//  Renders depth buffer directly as 3D points
//

import SwiftUI
import MetalKit
import ARKit
import simd

// MARK: - SwiftUI Wrapper

struct DepthPointCloudView: UIViewRepresentable {
    let depthSample: DepthVisualizationSample?

    func makeUIView(context: Context) -> MTKView {
        let metalView = MTKView()
        metalView.device = MTLCreateSystemDefaultDevice()
        metalView.clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 1)
        metalView.colorPixelFormat = .bgra8Unorm
        metalView.depthStencilPixelFormat = .depth32Float
        metalView.delegate = context.coordinator
        metalView.enableSetNeedsDisplay = false
        metalView.isPaused = false
        metalView.preferredFramesPerSecond = 20 // Reduced from 30 for performance

        if let device = metalView.device {
            context.coordinator.setupMetal(device: device, view: metalView)
        }

        return metalView
    }

    func updateUIView(_ metalView: MTKView, context: Context) {
        context.coordinator.updateDepthSample(depthSample)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    // MARK: - Coordinator

    class Coordinator: NSObject, MTKViewDelegate {
        private var device: MTLDevice?
        private var commandQueue: MTLCommandQueue?
        private var pipelineState: MTLRenderPipelineState?
        private var depthState: MTLDepthStencilState?
        private var computePipelineState: MTLComputePipelineState?

        private var depthSample: DepthVisualizationSample?
        private var depthTexture: MTLTexture?
        private var confidenceTexture: MTLTexture?

        // Particle accumulation buffer
        private var particleBuffer: MTLBuffer?
        private var currentParticleIndex: Int = 0
        private let maxParticles: Int = 100_000 // Reduced from 500k for performance

        // Camera movement tracking for 3D scanning
        private var lastCameraTransform: simd_float4x4?
        private let minMovementThreshold: Float = 0.05 // 5cm movement required

        private var rotation: Float = 0
        private var vertexCount: Int = 0

        // MARK: - Setup

        func setupMetal(device: MTLDevice, view: MTKView) {
            self.device = device
            self.commandQueue = device.makeCommandQueue()

            // Create shader library
            guard let library = device.makeDefaultLibrary() else {
                print("❌ Failed to create Metal library")
                return
            }

            // Create compute pipeline for accumulation
            do {
                let computeFunction = library.makeFunction(name: "accumulateDepthPoints")
                computePipelineState = try device.makeComputePipelineState(function: computeFunction!)
                print("✅ Created compute pipeline for accumulation")
            } catch {
                print("❌ Failed to create compute pipeline: \(error)")
            }

            // Create render pipeline for simple point cloud (matches Apple's approach)
            let pipelineDescriptor = MTLRenderPipelineDescriptor()
            pipelineDescriptor.vertexFunction = library.makeFunction(name: "simplePointCloudVertex")
            pipelineDescriptor.fragmentFunction = library.makeFunction(name: "simplePointCloudFragment")
            pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
            pipelineDescriptor.colorAttachments[0].isBlendingEnabled = true
            pipelineDescriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
            pipelineDescriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
            pipelineDescriptor.depthAttachmentPixelFormat = .depth32Float

            do {
                pipelineState = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
                print("✅ Created render pipeline for particles")
            } catch {
                print("❌ Failed to create pipeline state: \(error)")
            }

            // Create depth state
            let depthDescriptor = MTLDepthStencilDescriptor()
            depthDescriptor.depthCompareFunction = .less
            depthDescriptor.isDepthWriteEnabled = true
            depthState = device.makeDepthStencilState(descriptor: depthDescriptor)

            // Create particle buffer
            let particleSize = MemoryLayout<SIMD4<Float>>.stride * 2 // position(xyz+pad) + color(rgb+confidence)
            let bufferSize = maxParticles * particleSize
            particleBuffer = device.makeBuffer(length: bufferSize, options: .storageModeShared)
            print("✅ Created particle buffer for \(maxParticles) particles (\(bufferSize / 1024 / 1024)MB)")
        }

        // MARK: - Update Sample

        func updateDepthSample(_ sample: DepthVisualizationSample?) {
            guard let sample = sample, let device = device else { return }

            // Create Metal textures immediately and DON'T store the sample
            // This prevents ARFrame retention issues
            createTexturesFromDepthSample(device: device, sample: sample)

            // Store only the metadata we need, not the CVPixelBuffers
            self.depthSample = sample
        }

        // MARK: - MTKViewDelegate

        func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
            // Handle resize
        }

        private var frameCount = 0

        func draw(in view: MTKView) {
            guard let commandQueue = commandQueue,
                  let pipelineState = pipelineState,
                  let depthState = depthState,
                  let drawable = view.currentDrawable,
                  let descriptor = view.currentRenderPassDescriptor,
                  let depthSample = depthSample,
                  let depthTexture = depthTexture else {
                if frameCount % 30 == 0 {
                    print("❌ Draw guard failed:")
                    print("   commandQueue: \(commandQueue != nil)")
                    print("   pipelineState: \(pipelineState != nil)")
                    print("   depthState: \(depthState != nil)")
                    print("   drawable: \(view.currentDrawable != nil)")
                    print("   descriptor: \(view.currentRenderPassDescriptor != nil)")
                    print("   depthSample: \(depthSample != nil)")
                    print("   depthTexture: \(depthTexture != nil)")
                }
                frameCount += 1
                return
            }

            guard let commandBuffer = commandQueue.makeCommandBuffer() else {
                return
            }

            guard let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor) else {
                return
            }

            renderEncoder.setRenderPipelineState(pipelineState)
            renderEncoder.setDepthStencilState(depthState)

            // Simple approach like Apple's sample: Identity view matrix (camera space)
            let viewMatrix = simd_float4x4(1.0) // Identity - render in camera space
            let projectionMatrix = depthSample.projectionMatrix
            let viewProjectionMatrix = projectionMatrix * viewMatrix

            struct PointCloudUniforms {
                var viewProjectionMatrix: simd_float4x4
                var fx: Float
                var fy: Float
                var cx: Float
                var cy: Float
                var depthResolution: SIMD2<Float>
                var pointSize: Float
                var confidenceThreshold: Int32
            }

            let K = depthSample.intrinsics
            var uniforms = PointCloudUniforms(
                viewProjectionMatrix: viewProjectionMatrix,
                fx: K[0][0],
                fy: K[1][1],
                cx: K[2][0],
                cy: K[2][1],
                depthResolution: SIMD2<Float>(Float(depthTexture.width), Float(depthTexture.height)),
                pointSize: 8.0,
                confidenceThreshold: 0
            )

            renderEncoder.setVertexBytes(&uniforms, length: MemoryLayout<PointCloudUniforms>.stride, index: 0)
            renderEncoder.setVertexTexture(depthTexture, index: 0)
            if let confidenceTexture = confidenceTexture {
                renderEncoder.setVertexTexture(confidenceTexture, index: 1)
            }

            // Draw ALL depth pixels as points (current frame only)
            let vertexCount = Int(depthTexture.width * depthTexture.height)
            renderEncoder.drawPrimitives(type: .point, vertexStart: 0, vertexCount: vertexCount)

            frameCount += 1
            if frameCount % 30 == 0 {
                print("🎨 Drawing \(vertexCount) points (current frame)")
                print("   Depth texture: \(depthTexture.width)x\(depthTexture.height)")
                print("   View size: \(view.bounds.size)")
                print("   Camera intrinsics: fx=\(uniforms.fx), fy=\(uniforms.fy), cx=\(uniforms.cx), cy=\(uniforms.cy)")
                print("   Projection matrix valid: \(projectionMatrix != simd_float4x4())")

                // Sample some depth values
                let depthData = depthSample.depthMap
                CVPixelBufferLockBaseAddress(depthData, .readOnly)
                if let baseAddress = CVPixelBufferGetBaseAddress(depthData) {
                    let depthPtr = baseAddress.assumingMemoryBound(to: Float.self)
                    var validCount = 0
                    for i in 0..<min(100, Int(depthTexture.width * depthTexture.height)) {
                        if depthPtr[i] > 0 { validCount += 1 }
                    }
                    print("   Valid depth samples: \(validCount)/100")
                }
                CVPixelBufferUnlockBaseAddress(depthData, .readOnly)
            }

            renderEncoder.endEncoding()
            commandBuffer.present(drawable)
            commandBuffer.commit()
        }

        // MARK: - Texture Creation

        private func createTexturesFromDepthSample(device: MTLDevice, sample: DepthVisualizationSample) {
            let width = sample.width
            let height = sample.height
            vertexCount = width * height

            // Create depth texture from CVPixelBuffer
            let depthBuffer = sample.depthMap

            CVPixelBufferLockBaseAddress(depthBuffer, .readOnly)
            defer { CVPixelBufferUnlockBaseAddress(depthBuffer, .readOnly) }

            let depthDescriptor = MTLTextureDescriptor.texture2DDescriptor(
                pixelFormat: .r32Float,
                width: width,
                height: height,
                mipmapped: false
            )
            depthDescriptor.usage = [.shaderRead]

            guard let texture = device.makeTexture(descriptor: depthDescriptor) else {
                print("❌ Failed to create depth texture")
                return
            }

            // Copy depth data from CVPixelBuffer to Metal texture
            if let baseAddress = CVPixelBufferGetBaseAddress(depthBuffer) {
                let bytesPerRow = CVPixelBufferGetBytesPerRow(depthBuffer)
                texture.replace(
                    region: MTLRegionMake2D(0, 0, width, height),
                    mipmapLevel: 0,
                    withBytes: baseAddress,
                    bytesPerRow: bytesPerRow
                )

                // DEBUG: Sample some depth values to verify they're reasonable
                let depthPtr = baseAddress.assumingMemoryBound(to: Float.self)
                var minDepth: Float = 100
                var maxDepth: Float = 0
                var validPoints = 0
                for i in 0..<min(100, width * height) {
                    let depth = depthPtr[i]
                    if depth > 0 {
                        minDepth = min(minDepth, depth)
                        maxDepth = max(maxDepth, depth)
                        validPoints += 1
                    }
                }
                print("🔍 Depth range: \(minDepth)m to \(maxDepth)m, valid points in sample: \(validPoints)/100")
                print("🔍 Camera intrinsics fx=\(sample.intrinsics[0][0]), fy=\(sample.intrinsics[1][1])")
            }

            self.depthTexture = texture

            // Create confidence texture if available
            if let confidenceBuffer = sample.confidenceMap {
                CVPixelBufferLockBaseAddress(confidenceBuffer, .readOnly)
                defer { CVPixelBufferUnlockBaseAddress(confidenceBuffer, .readOnly) }

                let confidenceDescriptor = MTLTextureDescriptor.texture2DDescriptor(
                    pixelFormat: .r8Uint,
                    width: width,
                    height: height,
                    mipmapped: false
                )
                confidenceDescriptor.usage = [.shaderRead]

                guard let confTexture = device.makeTexture(descriptor: confidenceDescriptor) else {
                    print("❌ Failed to create confidence texture")
                    return
                }

                if let confAddress = CVPixelBufferGetBaseAddress(confidenceBuffer) {
                    let bytesPerRow = CVPixelBufferGetBytesPerRow(confidenceBuffer)
                    confTexture.replace(
                        region: MTLRegionMake2D(0, 0, width, height),
                        mipmapLevel: 0,
                        withBytes: confAddress,
                        bytesPerRow: bytesPerRow
                    )
                }

                self.confidenceTexture = confTexture
            }
        }

        // MARK: - Matrix Math

        private func makeRotationMatrix(_ angle: Float) -> simd_float4x4 {
            let cos = cosf(angle)
            let sin = sinf(angle)
            return simd_float4x4(
                SIMD4<Float>(cos, 0, sin, 0),
                SIMD4<Float>(0, 1, 0, 0),
                SIMD4<Float>(-sin, 0, cos, 0),
                SIMD4<Float>(0, 0, 0, 1)
            )
        }

        // MARK: - Helpers

        private func distance(_ a: SIMD4<Float>, _ b: SIMD4<Float>) -> Float {
            let dx = a.x - b.x
            let dy = a.y - b.y
            let dz = a.z - b.z
            return sqrtf(dx*dx + dy*dy + dz*dz)
        }

        private func makeOrbitViewMatrix(rotation: Float, distance: Float) -> simd_float4x4 {
            // Orbital camera that rotates around the accumulated point cloud
            let eye = SIMD3<Float>(
                sinf(rotation) * distance,
                0.0,
                cosf(rotation) * distance
            )
            let center = SIMD3<Float>(0, 0, 0) // Look at world origin
            let up = SIMD3<Float>(0, 1, 0) // Y-up for world space

            let z = normalize(eye - center)
            let x = normalize(cross(up, z))
            let y = cross(z, x)

            return simd_float4x4(
                SIMD4<Float>(x.x, y.x, z.x, 0),
                SIMD4<Float>(x.y, y.y, z.y, 0),
                SIMD4<Float>(x.z, y.z, z.z, 0),
                SIMD4<Float>(-dot(x, eye), -dot(y, eye), -dot(z, eye), 1)
            )
        }

        private func makeProjectionMatrix(aspectRatio: Float) -> simd_float4x4 {
            let fov: Float = Float.pi / 2 // Wider field of view (90 degrees, was 60)
            let near: Float = 0.01 // Very close near plane
            let far: Float = 10 // Closer far plane for better depth precision

            let yScale = 1 / tanf(fov * 0.5)
            let xScale = yScale / aspectRatio
            let zRange = far - near
            let zScale = -(far + near) / zRange
            let wzScale = -2 * far * near / zRange

            return simd_float4x4(
                SIMD4<Float>(xScale, 0, 0, 0),
                SIMD4<Float>(0, yScale, 0, 0),
                SIMD4<Float>(0, 0, zScale, -1),
                SIMD4<Float>(0, 0, wzScale, 0)
            )
        }
    }
}

// MARK: - Depth Uniforms

struct DepthUniforms {
    let viewMatrix: simd_float4x4
    let projectionMatrix: simd_float4x4
    let inverseIntrinsics: simd_float3x3
    let localToWorld: simd_float4x4
    let depthResolution: SIMD2<Float>
    let pointSize: Float
    let confidenceThreshold: Int32

    init(viewMatrix: simd_float4x4,
         projectionMatrix: simd_float4x4,
         inverseIntrinsics: simd_float3x3,
         localToWorld: simd_float4x4,
         depthResolution: SIMD2<Float>,
         pointSize: Float,
         confidenceThreshold: Int) {
        self.viewMatrix = viewMatrix
        self.projectionMatrix = projectionMatrix
        self.inverseIntrinsics = inverseIntrinsics
        self.localToWorld = localToWorld
        self.depthResolution = depthResolution
        self.pointSize = pointSize
        self.confidenceThreshold = Int32(confidenceThreshold)
    }
}

// MARK: - simd_float3x3 Extension

extension simd_float3x3 {
    var inverse: simd_float3x3 {
        return simd_inverse(self)
    }
}
