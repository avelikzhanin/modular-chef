# Design System Document: The Clinical Ethereal

## 1. Overview & Creative North Star
**Creative North Star: "The Curated Sanctuary"**

This design system rejects the sterile, rigid grid of traditional medical and wellness interfaces in favor of a "Curated Sanctuary"—an environment that feels intentionally airy, breathably soft, and intellectually calm. We move beyond "standard" UI by utilizing **intentional asymmetry** and **tonal depth** rather than structural containment. 

By prioritizing "Clinical Softness," we replace the anxiety of high-contrast data with a sensory-led experience. This is achieved through a "Zero-Line" philosophy and a reliance on chromatic layering, ensuring the interface feels like a seamless extension of a physical space rather than a digital tool.

---

## 2. Colors & Chromatic Layering
The palette is built on a foundation of powdery pinks and cool greys, punctuated by a restorative pistachio green.

### The "No-Line" Rule
To maintain the "Sanctuary" aesthetic, **1px solid borders are strictly prohibited for sectioning.** Boundaries must be defined solely through background color shifts or subtle tonal transitions. For instance, a `surface-container-low` section should sit directly on a `surface` background to create a "soft-edge" division.

### Surface Hierarchy & Nesting
Treat the UI as a series of physical layers—like stacked sheets of fine, semi-translucent paper.
*   **Base:** `surface` (#f8f9fb)
*   **Lower Tier:** `surface-container-low` (#f0f4f7) for secondary navigation or background grouping.
*   **Active Tier:** `surface-container-lowest` (#ffffff) for primary content cards and floating modules.
*   **Depth Rule:** Always nest a "lighter" surface within a "darker" surface to create a natural, upward lift toward the user.

### The "Glass & Gradient" Rule
To add professional polish, primary CTAs and Hero sections should utilize a **Signature Texture**:
*   **Gradients:** Use a subtle linear transition from `primary_fixed` (#cbe9dc) to `primary` (#49655a) at a 15% opacity overlay to provide "soul" to flat surfaces.
*   **Glassmorphism:** For floating modals or navigation bars, use `surface_container_lowest` at 80% opacity with a `24px` backdrop-blur. This allows the soft pinks and greys to bleed through, softening the interface's digital edges.

---

## 3. Typography: The Rounded Editorial
We utilize **Inter (Rounded)** to bridge the gap between clinical precision and human warmth.

*   **Display (LG/MD/SM):** Use for high-impact editorial moments. Set with tight letter-spacing (-0.02em) to create an authoritative, "magazine" feel.
*   **Headline & Title:** These are your navigational anchors. Use `headline-md` for section starts, ensuring generous top-padding to let the type "breathe."
*   **Body (LG/MD/SM):** Set in `on_surface_variant` (#596064) for long-form reading to reduce eye strain against the powdery pink backgrounds.
*   **Labels:** Use `label-md` in all-caps with +0.05em tracking for a sophisticated, disciplined secondary hierarchy.

---

## 4. Elevation & Depth
In this system, depth is a whisper, not a shout.

*   **The Layering Principle:** Avoid shadows for static content. Achieve hierarchy by stacking `surface-container-lowest` (#ffffff) cards on a `surface-container` (#eaeef2) background.
*   **Ambient Shadows:** When a floating state is required (e.g., a triggered dropdown), use a "Sanctuary Shadow": 
    *   `box-shadow: 0 12px 32px rgba(44, 51, 55, 0.04);` 
    *   Note: The shadow color is a tinted version of `on_surface`, never pure black.
*   **The "Ghost Border" Fallback:** If accessibility requires a container edge, use the `outline_variant` token at **15% opacity**. A 100% opaque border is considered a design failure in this system.

---

## 5. Components

### Buttons & Interactive Elements
*   **Primary Action:** Background: `primary_container` (#cbe9dc). Text: `on_primary_container` (#3c574d). 
    *   *Styling:* 100px (Full) pill shape. No shadow. On hover, transition to `primary_fixed_dim`.
*   **Secondary Action:** Background: `secondary_container` (#f0dede). Text: `on_secondary_container`.
*   **Tertiary:** Ghost style using `primary` text. No container.

### Cards & Content Modules
*   **Constraint:** Forbid the use of divider lines.
*   **Separation:** Use `40px` or `64px` vertical margins from the spacing scale to separate content blocks.
*   **Shape:** Apply `xl` (1.5rem) roundedness to all primary content cards to reinforce the "Clinical Softness" V4 mandate.

### Input Fields
*   **Base State:** `surface_container_high` background with a `sm` (0.25rem) corner radius.
*   **Focus State:** Shift background to `surface_lowest` and apply a 2px "Ghost Border" using `primary` at 20% opacity.
*   **Helper Text:** Always use `body-sm` in `on_surface_variant`.

### Chips & Tags
*   **Selection Chips:** Use `tertiary_container` (#fde5ec) for a soft contrast against the pistachio accents. Shape must always be `full` (9999px).

---

## 6. Do's and Don'ts

### Do
*   **Do** use asymmetrical layouts. Place a small `title-sm` element offset against a large `display-md` headline to create editorial tension.
*   **Do** use whitespace as a functional element. If a screen feels "busy," increase the padding rather than adding a border.
*   **Do** ensure all pistachio green (`primary`) elements maintain a "muted" quality. If it looks "neon," reduce saturation immediately.

### Don't
*   **Don't** use 1px dividers or "hairline" rules. They break the fluid, airy immersion of the system.
*   **Don't** use dark mode in a traditional sense. If a "Dark" version is needed, it should move into deep, desaturated "Cool Greys" (`inverse_surface`), never pure #000000.
*   **Don't** use sharp corners. Every interactive element must have at least a `sm` (0.25rem) radius to stay on-brand.