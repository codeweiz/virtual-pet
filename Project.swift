import ProjectDescription

// ─────────────────────────────────────────────────────────────────────────────
// VirtualPet — Tuist project graph
//
// Layering (deps point DOWN only — see docs/ModularizationGuide.md):
//   Apps  →  Features  →  UI (DesignSystem · VisualFX · PetRenderer)  →  Core
//   Core  =  PetKit · PetPersistence · PetSync · PetIntents · PetWidgetShared
//
// watchOS reality: no Metal → VisualFX (shaders) is iPhone/iPad/Mac only; the
// watch renders the pet via PetRenderer's Canvas tier. App/UI targets opt into
// MainActor-by-default; Core packages stay nonisolated.
// ─────────────────────────────────────────────────────────────────────────────

let org = "com.microboat.virtualpet"
let appGroup = "group.com.microboat.virtualpet"

let allApple: Destinations = [.iPhone, .iPad, .mac, .appleWatch]
let phoneMac: Destinations = [.iPhone, .iPad, .mac]
let watchOnly: Destinations = [.appleWatch]

let allDeploy: DeploymentTargets = .multiplatform(iOS: "26.0", macOS: "26.0", watchOS: "26.0")
let phoneMacDeploy: DeploymentTargets = .multiplatform(iOS: "26.0", macOS: "26.0")
let watchDeploy: DeploymentTargets = .watchOS("26.0")

// Core packages: Swift 6 strict concurrency, NO forced main-actor isolation.
let coreSettings = Settings.settings(base: [
    "SWIFT_VERSION": "6.0",
    "SWIFT_STRICT_CONCURRENCY": "complete",
    "SWIFT_APPROACHABLE_CONCURRENCY": "YES",
])

// UI / app targets: also default to MainActor isolation (approachable concurrency).
let uiSettings = Settings.settings(base: [
    "SWIFT_VERSION": "6.0",
    "SWIFT_STRICT_CONCURRENCY": "complete",
    "SWIFT_APPROACHABLE_CONCURRENCY": "YES",
    "SWIFT_DEFAULT_ACTOR_ISOLATION": "MainActor",
])

// MARK: - Factories

func framework(
    _ name: String,
    destinations: Destinations = allApple,
    deployment: DeploymentTargets = allDeploy,
    dependencies: [TargetDependency] = [],
    settings: Settings = coreSettings,
    hasResources: Bool = false
) -> Target {
    .target(
        name: name,
        destinations: destinations,
        product: .framework,
        bundleId: "\(org).\(name.lowercased())",
        deploymentTargets: deployment,
        sources: ["Modules/\(name)/Sources/**"],
        resources: hasResources ? ["Modules/\(name)/Resources/**"] : [],
        dependencies: dependencies,
        settings: settings
    )
}

func unitTests(
    _ name: String,
    testing moduleUnderTest: String,
    destinations: Destinations = [.iPhone, .mac],
    deployment: DeploymentTargets = phoneMacDeploy
) -> Target {
    .target(
        name: name,
        destinations: destinations,
        product: .unitTests,
        bundleId: "\(org).\(name.lowercased())",
        deploymentTargets: deployment,
        sources: ["Modules/\(moduleUnderTest)/Tests/**"],
        dependencies: [.target(name: moduleUnderTest)],
        settings: coreSettings
    )
}

// MARK: - Targets

let targets: [Target] = [
    // ── Core ──────────────────────────────────────────────────────────────────
    framework("PetKit"),
    unitTests("PetKitTests", testing: "PetKit"),
    framework("PetPersistence", dependencies: [.target(name: "PetKit")]),
    framework("PetSync", dependencies: [.target(name: "PetKit")]),
    framework(
        "PetIntents",
        dependencies: [.target(name: "PetKit"), .target(name: "PetPersistence")]
    ),
    framework("PetWidgetShared", dependencies: [.target(name: "PetKit")]),

    // ── UI ────────────────────────────────────────────────────────────────────
    framework("DesignSystem", settings: uiSettings),
    framework("VisualFX", destinations: phoneMac, deployment: phoneMacDeploy, settings: uiSettings),
    framework(
        "PetRenderer",
        dependencies: [.target(name: "PetKit"), .target(name: "DesignSystem")],
        settings: uiSettings
    ),
    // Rive-backed pet — iOS/iPad/Mac only (no Rive/Metal on watchOS).
    framework(
        "PetRendererRive",
        destinations: phoneMac,
        deployment: phoneMacDeploy,
        dependencies: [
            .target(name: "PetKit"),
            .target(name: "PetRenderer"),
            .package(product: "RiveRuntime"),
        ],
        settings: uiSettings,
        hasResources: true
    ),

    // ── Features ────────────────────────────────────────────────────────────────
    framework(
        "FeaturePetHome",
        dependencies: [
            .target(name: "PetKit"),
            .target(name: "DesignSystem"),
            .target(name: "PetRenderer"),
            .target(name: "PetPersistence"),
            .target(name: "PetIntents"),
            .target(name: "PetSync"),
            .target(name: "PetWidgetShared"),
        ],
        settings: uiSettings
    ),

    // ── Apps ──────────────────────────────────────────────────────────────────
    .target(
        name: "PetApp",
        destinations: phoneMac,
        product: .app,
        bundleId: org,
        deploymentTargets: phoneMacDeploy,
        infoPlist: .extendingDefault(with: [
            "CFBundleDisplayName": "VirtualPet",
            "UILaunchScreen": ["UIColorName": ""],
            "ITSAppUsesNonExemptEncryption": false,
            "NSSupportsLiveActivities": true,
        ]),
        sources: ["Apps/PetApp/Sources/**"],
        entitlements: .dictionary([
            "com.apple.security.application-groups": .array([.string(appGroup)])
        ]),
        dependencies: [
            .target(name: "FeaturePetHome"),
            .target(name: "VisualFX"),
            .target(name: "PetRendererRive"),
            // Direct dep so the RiveRuntime binary framework is embedded in the
            // app bundle (transitive SPM binary frameworks aren't auto-embedded).
            .package(product: "RiveRuntime"),
        ],
        settings: uiSettings
    ),
    .target(
        name: "PetWatchApp",
        destinations: watchOnly,
        product: .app,
        bundleId: "\(org).watchkitapp",
        deploymentTargets: watchDeploy,
        infoPlist: .extendingDefault(with: [
            "CFBundleDisplayName": "VirtualPet",
            "WKApplication": true,
            "WKRunsIndependentlyOfCompanionApp": true,
        ]),
        sources: ["Apps/PetWatchApp/Sources/**"],
        dependencies: [
            .target(name: "FeaturePetHome")
        ],
        settings: uiSettings
    ),
    .target(
        name: "PetWidgets",
        destinations: [.iPhone, .iPad],
        product: .appExtension,
        bundleId: "\(org).widgets",
        deploymentTargets: .iOS("26.0"),
        infoPlist: .extendingDefault(with: [
            "CFBundleDisplayName": "VirtualPet Widgets",
            "NSExtension": [
                "NSExtensionPointIdentifier": "com.apple.widgetkit-extension"
            ],
        ]),
        sources: ["Apps/PetWidgets/Sources/**"],
        entitlements: .dictionary([
            "com.apple.security.application-groups": .array([.string(appGroup)])
        ]),
        dependencies: [
            .target(name: "PetWidgetShared"),
            .target(name: "DesignSystem"),
            .target(name: "PetIntents"),
            .target(name: "PetPersistence"),
        ],
        settings: uiSettings
    ),
]

// MARK: - Schemes

let schemes: [Scheme] = [
    .scheme(
        name: "PetApp",
        shared: true,
        buildAction: .buildAction(targets: ["PetApp"]),
        testAction: .targets(["PetKitTests"]),
        runAction: .runAction(executable: "PetApp")
    ),
    .scheme(
        name: "PetWatchApp",
        shared: true,
        buildAction: .buildAction(targets: ["PetWatchApp"]),
        runAction: .runAction(executable: "PetWatchApp")
    ),
]

let project = Project(
    name: "VirtualPet",
    organizationName: "Microboat",
    options: .options(
        automaticSchemesOptions: .enabled(),
        developmentRegion: "en"
    ),
    packages: [
        .remote(
            url: "https://github.com/rive-app/rive-ios",
            requirement: .upToNextMajor(from: "6.20.6")
        )
    ],
    settings: coreSettings,
    targets: targets,
    schemes: schemes
)
