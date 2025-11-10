//
//  DepthPointCloud.metal
//  arvos
//
//  High-performance depth map to point cloud visualization
//  Based on Apple's ARKit scene depth best practices
//

#include <metal_stdlib>
using namespace metal;

// MARK: - Structs

struct DepthUniforms {
    float4x4 viewMatrix;
    float4x4 projectionMatrix;
    float3x3 inverseIntrinsics;
    float2 depthResolution;
    float pointSize;
    int confidenceThreshold; // 0=low, 1=medium, 2=high
};

struct ParticleVertexOut {
    float4 position [[position]];
    float3 color;
    float pointSize [[point_size]];
};

// MARK: - Unproject Depth to 3D Position

/// Unprojects a 2D depth pixel to 3D camera space using camera intrinsics
/// This is the core algorithm for depth-to-point-cloud conversion
float3 unprojectDepthSample(float2 pixelCoord,
                            float depth,
                            float3x3 inverseIntrinsics,
                            float2 depthResolution) {
    // Use pixel coordinates directly for unprojection
    float2 imageCoord = float2(pixelCoord.x, pixelCoord.y);

    // Unproject using inverse camera intrinsics
    // Formula: position = inverse(K) * [x, y, 1] * depth
    float3 homogeneous = float3(imageCoord, 1.0);
    float3 cameraSpace = inverseIntrinsics * homogeneous;

    // Scale by depth value
    return cameraSpace * depth;
}

// MARK: - Vertex Shader

/// Vertex shader for depth point cloud rendering
/// Each vertex represents one depth pixel
vertex ParticleVertexOut depthPointCloudVertex(
    uint vertexID [[vertex_id]],
    constant DepthUniforms& uniforms [[buffer(0)]],
    texture2d<float, access::sample> depthTexture [[texture(0)]],
    texture2d<uint, access::sample> confidenceTexture [[texture(1)]],
    texture2d<float, access::sample> colorTexture [[texture(2)]]
) {
    ParticleVertexOut out;

    // Calculate 2D position in depth map
    uint depthWidth = uint(uniforms.depthResolution.x);

    uint x = vertexID % depthWidth;
    uint y = vertexID / depthWidth;

    // Sample depth value
    constexpr sampler depthSampler(coord::pixel, filter::nearest);
    float2 depthCoord = float2(x, y);
    float depth = depthTexture.sample(depthSampler, depthCoord).r;

    // Sample confidence (if available)
    uint confidence = 0;
    if (uniforms.confidenceThreshold >= 0) {
        confidence = confidenceTexture.sample(depthSampler, depthCoord).r;

        // Filter by confidence threshold
        // ARFrameDepthConfidence: 0=low, 1=medium, 2=high
        if (int(confidence) < uniforms.confidenceThreshold) {
            // Discard low confidence points by moving off-screen
            out.position = float4(0, 0, -1000, 1);
            out.color = float3(0);
            out.pointSize = 0;
            return out;
        }
    }

    // Unproject depth to 3D camera space
    float3 localPosition = unprojectDepthSample(
        depthCoord,
        depth,
        uniforms.inverseIntrinsics,
        uniforms.depthResolution
    );

    // Transform to world space and then to clip space
    float4 worldPosition = float4(localPosition, 1.0);
    out.position = uniforms.projectionMatrix * uniforms.viewMatrix * worldPosition;

    // Sample color from camera image
    // Map depth coordinates to color image coordinates
    float2 colorCoord = depthCoord / uniforms.depthResolution;
    constexpr sampler colorSampler(coord::normalized, filter::linear);
    float4 color = colorTexture.sample(colorSampler, colorCoord);
    out.color = color.rgb;

    // Point size based on distance (perspective effect)
    float distance = length(localPosition);
    out.pointSize = uniforms.pointSize / max(distance * 0.1, 1.0);

    return out;
}

// MARK: - Fragment Shader

/// Fragment shader for point cloud particles
fragment float4 depthPointCloudFragment(ParticleVertexOut in [[stage_in]],
                                         float2 pointCoord [[point_coord]]) {
    // Create circular particles
    float2 center = pointCoord - float2(0.5);
    float dist = length(center);

    // Smooth circle edge
    float alpha = 1.0 - smoothstep(0.4, 0.5, dist);

    if (alpha < 0.01) {
        discard_fragment();
    }

    return float4(in.color, alpha);
}
