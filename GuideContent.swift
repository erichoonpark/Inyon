import Foundation

// MARK: - Content Models

struct GuideSection: Identifiable {
    let id: String
    let title: String
    let iconName: String
    let summary: String
    let learnMoreBullets: [String]
}

struct ElementItem: Identifiable {
    var id: String { name }
    let name: String
    let iconName: String
    let shortDesc: String
    let detailBullets: [String]
}

struct IsIsNotItem {
    let text: String
}

// MARK: - Static Content

enum GuideContent {

    // MARK: - What Is Saju

    static let whatIsSaju = GuideSection(
        id: "what_is_saju",
        title: "What Is Saju?",
        iconName: "square.stack.3d.up",
        summary: "Saju is a Korean framework for understanding personal timing and tendencies. It reflects patterns based on the moment you were born—not to predict the future, but to offer perspective.",
        learnMoreBullets: [
            "Saju (사주) translates to 'four pillars.' It originated from classical East Asian cosmology and has been practiced in Korea for centuries.",
            "Unlike Western astrology, Saju doesn't use zodiac signs or planetary houses. It focuses on elemental balance and cyclical time.",
            "People use Saju today for self-reflection, understanding relationships, and noticing favorable conditions—not for fortune-telling."
        ]
    )

    // MARK: - How Saju Is Structured

    static let howStructured = GuideSection(
        id: "how_structured",
        title: "How Saju Is Structured",
        iconName: "rectangle.split.3x1",
        summary: "Your Saju chart has four pillars: Year, Month, Day, and Hour. Each pillar contains two layers—a Heavenly Stem and an Earthly Branch—creating eight characters in total.",
        learnMoreBullets: [
            "The Day Pillar is often considered the core of your chart. It tends to reflect your fundamental nature.",
            "The Hour Pillar adds nuance. If your birth time is unknown, Saju can still offer meaningful insight from the other three pillars.",
            "Context matters: the same elements can express differently depending on surrounding pillars and overall balance."
        ]
    )

    // MARK: - Five Elements

    static let elements: [ElementItem] = [
        ElementItem(
            name: "Wood",
            iconName: "leaf",
            shortDesc: "Growth, flexibility, vision",
            detailBullets: [
                "Wood energy tends to seek expansion and new beginnings.",
                "It can reflect creativity, ambition, and forward momentum.",
                "When imbalanced, it may feel like restlessness or scattered focus."
            ]
        ),
        ElementItem(
            name: "Fire",
            iconName: "flame",
            shortDesc: "Warmth, expression, clarity",
            detailBullets: [
                "Fire energy often shows up as enthusiasm and visibility.",
                "It can reflect confidence, connection, and illumination.",
                "When imbalanced, it may feel like burnout or impulsiveness."
            ]
        ),
        ElementItem(
            name: "Earth",
            iconName: "square.on.square",
            shortDesc: "Stability, nourishment, grounding",
            detailBullets: [
                "Earth energy tends to anchor and support.",
                "It can reflect reliability, patience, and thoughtfulness.",
                "When imbalanced, it may feel like stagnation or overthinking."
            ]
        ),
        ElementItem(
            name: "Metal",
            iconName: "circle.hexagongrid",
            shortDesc: "Structure, refinement, precision",
            detailBullets: [
                "Metal energy often shows up as clarity and discernment.",
                "It can reflect discipline, boundaries, and decisiveness.",
                "When imbalanced, it may feel like rigidity or detachment."
            ]
        ),
        ElementItem(
            name: "Water",
            iconName: "drop",
            shortDesc: "Depth, intuition, adaptability",
            detailBullets: [
                "Water energy tends to flow and adapt.",
                "It can reflect wisdom, emotional depth, and resourcefulness.",
                "When imbalanced, it may feel like fear or lack of direction."
            ]
        )
    ]

    static let elementsSection = GuideSection(
        id: "five_elements",
        title: "The Five Elements",
        iconName: "pentagon",
        summary: "Saju uses five elements—Wood, Fire, Earth, Metal, and Water—to describe different types of energy. Everyone's chart contains all five in varying proportions.",
        learnMoreBullets: [
            "Balance doesn't mean equal amounts. It means how well the elements support each other in your specific chart.",
            "No element is inherently good or bad. Each has strengths and challenges depending on context.",
            "Imbalance can feel like friction—but it also often signals areas of growth or attention."
        ]
    )

    // MARK: - Reading a Chart

    static let readingChart = GuideSection(
        id: "reading_chart",
        title: "Reading a Chart",
        iconName: "doc.text.magnifyingglass",
        summary: "Reading Saju is about noticing patterns, not labeling outcomes. It starts with your Day Element and looks at how other elements interact with it.",
        learnMoreBullets: [
            "Step 1: Identify your Day Element. This tends to reflect your core nature and how you process the world.",
            "Step 2: Notice which elements support or challenge your Day Element. Support can feel like ease; challenge can feel like friction.",
            "Step 3: Read relationships and flow, not fixed labels. A chart is a dynamic system, not a static snapshot.",
            "Two people with similar charts can experience life very differently. Context, choices, and timing all matter."
        ]
    )

    // MARK: - What Saju Is / Is Not

    static let isItems: [IsIsNotItem] = [
        IsIsNotItem(text: "A framework for reflection"),
        IsIsNotItem(text: "Based on time and elemental patterns"),
        IsIsNotItem(text: "A tool for noticing tendencies"),
        IsIsNotItem(text: "Open to interpretation")
    ]

    static let isNotItems: [IsIsNotItem] = [
        IsIsNotItem(text: "A prediction of the future"),
        IsIsNotItem(text: "A guarantee of outcomes"),
        IsIsNotItem(text: "A replacement for personal judgment"),
        IsIsNotItem(text: "Fixed or absolute")
    ]

    // MARK: - How Inyon Uses Saju

    static let howInyonUses = GuideSection(
        id: "how_inyon_uses",
        title: "How Inyon Uses Saju",
        iconName: "sparkles",
        summary: "Inyon interprets your chart to surface daily reflections grounded in Saju principles. We focus on conditions and tendencies—never predictions or prescriptions.",
        learnMoreBullets: []
    )
}
