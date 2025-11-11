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
        metalView.preferredFramesPerSecond = 30

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
        private let maxParticles: Int = 500_000 // Accumulate up to 500k points

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

            // Create render pipeline for particles
            let pipelineDescriptor = MTLRenderPipelineDescriptor()
            pipelineDescriptor.vertexFunction = library.makeFunction(name: "particleVertex")
            pipelineDescriptor.fragmentFunction = library.makeFunction(name: "particleFragment")
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
            guard let device = device,
                  let commandQueue = commandQueue,
                  let computePipelineState = computePipelineState,
                  let pipelineState = pipelineState,
                  let depthState = depthState,
                  let particleBuffer = particleBuffer,
                  let drawable = view.currentDrawable,
                  let descriptor = view.currentRenderPassDescriptor,
                  let depthSample = depthSample,
                  let depthTexture = depthTexture else {
                return
            }

            guard let commandBuffer = commandQueue.makeCommandBuffer() else {
                return
            }

            // Check if camera has moved enough to accumulate new points (3D scanning behavior)
            let shouldAccumulate: Bool
            if let lastTransform = lastCameraTransform {
                let movement = distance(lastTransform.columns.3, depthSample.cameraTransform.columns.3)
                shouldAccumulate = movement > minMovementThreshold
            } else {
                shouldAccumulate = true // First frame
            }

            // STAGE 1: Accumulate depth points into particle buffer using compute shader
            if shouldAccumulate, let computeEncoder = commandBuffer.makeComputeCommandEncoder() {
                computeEncoder.setComputePipelineState(computePipelineState)

                lastCameraTransform = depthSample.cameraTransform

                // Accumulation uniforms
                struct AccumulationUniforms {
                    var cameraIntrinsicsInversed: simd_float3x3
                    var localToWorld: simd_float4x4
                    var depthResolution: SIMD2<Float>
                    var pointCloudCurrentIndex: Int32
                    var maxPoints: Int32
                    var confidenceThreshold: Int32
                }

                var accUniforms = AccumulationUniforms(
                    cameraIntrinsicsInversed: depthSample.intrinsics.inverse,
                    localToWorld: depthSample.cameraTransform,
                    depthResolution: SIMD2<Float>(Float(depthTexture.width), Float(depthTexture.height)),
                    pointCloudCurrentIndex: Int32(currentParticleIndex),
                    maxPoints: Int32(maxParticles),
                    confidenceThreshold: 0
                )

                computeEncoder.setBytes(&accUniforms, length: MemoryLayout<AccumulationUniforms>.stride, index: 0)
                computeEncoder.setBuffer(particleBuffer, offset: 0, index: 1)
                computeEncoder.setTexture(depthTexture, index: 0)
                if let confidenceTexture = confidenceTexture {
                    computeEncoder.setTexture(confidenceTexture, index: 1)
                }

                let threadgroupSize = MTLSize(width: 16, height: 16, depth: 1)
                let threadgroups = MTLSize(
                    width: (Int(depthTexture.width) + 15) / 16,
                    height: (Int(depthTexture.height) + 15) / 16,
                    depth: 1
                )
                computeEncoder.dispatchThreadgroups(threadgroups, threadsPerThreadgroup: threadgroupSize)
                computeEncoder.endEncoding()

                // Advance particle index
                currentParticleIndex = (currentParticleIndex + Int(depthTexture.width * depthTexture.height)) % maxParticles

                if frameCount % 30 == 0 {
                    print("📸 Camera moved - accumulating points (total: \(min(currentParticleIndex, maxParticles)))")
                }
            }

            // STAGE 2: Render accumulated particles
            guard let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor) else {
                return
            }

            renderEncoder.setRenderPipelineState(pipelineState)
            renderEncoder.setDepthStencilState(depthState)

            // Set up camera
            rotation += 0.005
            let viewMatrix = makeOrbitViewMatrix(rotation: rotation, distance: 3.0)
            let projectionMatrix = makeProjectionMatrix(aspectRatio: Float(view.bounds.width / view.bounds.height))
            let viewProjectionMatrix = projectionMatrix * viewMatrix

            struct RenderUniforms {
                var viewProjectionMatrix: simd_float4x4
                var pointSize: Float
                var confidenceThreshold: Int32
            }

            var renderUniforms = RenderUniforms(
                viewProjectionMatrix: viewProjectionMatrix,
                pointSize: 5.0, // Larger for better visibility
                confidenceThreshold: 0
            )

            renderEncoder.setVertexBytes(&renderUniforms, length: MemoryLayout<RenderUniforms>.stride, index: 0)
            renderEncoder.setVertexBuffer(particleBuffer, offset: 0, index: 1)

            // Draw all accumulated particles
            let particlesToDraw = min(currentParticleIndex + Int(depthTexture.width * depthTexture.height), maxParticles)
            renderEncoder.drawPrimitives(type: .point, vertexStart: 0, vertexCount: particlesToDraw)

            frameCount += 1
            if frameCount % 30 == 0 {
                print("🎨 Drawing \(particlesToDraw) accumulated particles at frame \(frameCount)")
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
