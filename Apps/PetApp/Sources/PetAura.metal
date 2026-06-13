#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>
using namespace metal;

// A dreamy, slowly-drifting aurora used as the pet's backdrop on iOS/iPad/Mac.
// `[[stitchable]]` + the (position, color, ...args) signature is the contract
// SwiftUI's `.colorEffect(_:)` expects. Driven by an elapsed-time uniform from
// TimelineView(.animation), so it animates without any @State.
[[ stitchable ]]
half4 petAura(float2 position, half4 color, float time, float2 size) {
    float2 uv = position / max(size, float2(1.0, 1.0));

    float wave = 0.5 + 0.5 * sin(time * 0.6
                                 + uv.x * 6.2831
                                 + sin(uv.y * 3.0 + time * 0.3) * 2.0);
    float radial = distance(uv, float2(0.5, 0.5));

    half3 top = half3(0.36h, 0.32h, 0.62h);
    half3 bottom = half3(0.20h, 0.18h, 0.38h);
    half3 accent = half3(0.62h, 0.45h, 0.95h);

    half3 base = mix(top, bottom, half(uv.y));
    half3 col = mix(base, accent, half(wave) * half(1.0 - radial) * 0.6h);
    return half4(col, 1.0h);
}
