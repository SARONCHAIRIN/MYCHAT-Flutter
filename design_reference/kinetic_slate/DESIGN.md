---
name: Kinetic Slate
colors:
  surface: '#f8f9ff'
  surface-dim: '#cbdbf5'
  surface-bright: '#f8f9ff'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#eff4ff'
  surface-container: '#e5eeff'
  surface-container-high: '#dce9ff'
  surface-container-highest: '#d3e4fe'
  on-surface: '#0b1c30'
  on-surface-variant: '#464555'
  inverse-surface: '#213145'
  inverse-on-surface: '#eaf1ff'
  outline: '#777587'
  outline-variant: '#c7c4d8'
  surface-tint: '#4d44e3'
  primary: '#3525cd'
  on-primary: '#ffffff'
  primary-container: '#4f46e5'
  on-primary-container: '#dad7ff'
  inverse-primary: '#c3c0ff'
  secondary: '#0058be'
  on-secondary: '#ffffff'
  secondary-container: '#2170e4'
  on-secondary-container: '#fefcff'
  tertiary: '#005338'
  on-tertiary: '#ffffff'
  tertiary-container: '#006e4b'
  on-tertiary-container: '#67f4b7'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#e2dfff'
  primary-fixed-dim: '#c3c0ff'
  on-primary-fixed: '#0f0069'
  on-primary-fixed-variant: '#3323cc'
  secondary-fixed: '#d8e2ff'
  secondary-fixed-dim: '#adc6ff'
  on-secondary-fixed: '#001a42'
  on-secondary-fixed-variant: '#004395'
  tertiary-fixed: '#6ffbbe'
  tertiary-fixed-dim: '#4edea3'
  on-tertiary-fixed: '#002113'
  on-tertiary-fixed-variant: '#005236'
  background: '#f8f9ff'
  on-background: '#0b1c30'
  surface-variant: '#d3e4fe'
typography:
  headline-lg:
    fontFamily: Inter
    fontSize: 28px
    fontWeight: '700'
    lineHeight: 34px
    letterSpacing: -0.02em
  headline-md:
    fontFamily: Inter
    fontSize: 24px
    fontWeight: '600'
    lineHeight: 30px
    letterSpacing: -0.015em
  title-lg:
    fontFamily: Inter
    fontSize: 22px
    fontWeight: '600'
    lineHeight: 28px
    letterSpacing: -0.01em
  title-md:
    fontFamily: Inter
    fontSize: 18px
    fontWeight: '600'
    lineHeight: 24px
    letterSpacing: -0.005em
  body-lg:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 22px
  body-md:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
  label-md:
    fontFamily: Inter
    fontSize: 13px
    fontWeight: '500'
    lineHeight: 16px
  caption-sm:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '400'
    lineHeight: 15px
  micro-badge:
    fontFamily: Inter
    fontSize: 10px
    fontWeight: '600'
    lineHeight: 12px
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  gutter: 1rem
  margin: 1rem
  space-xs: 0.25rem
  space-sm: 0.5rem
  space-md: 0.75rem
  space-lg: 1rem
  space-xl: 1.5rem
---

## Brand & Style

This design system defines a high-performance, polished mobile messaging experience tailored for iOS and Android environments. The brand personality balances hyper-functional utility with modern tactile polish: fast, dependable, fluid, and uncluttered. 

The aesthetic blends **Modern Minimalism** with subtle **Frosted Surfaces (Glassmorphism)** and crisp tonal layering:
- **Atmosphere:** Clean, ambient, and light-handed. Content takes precedence over chrome; messages, media, and contact identity remain primary visual anchors.
- **Micro-Interactions:** Subtle haptic feedback, fluid spring animations on bubble delivery, smooth swipe-to-reply gestures, and soft visual states for delivery updates.
- **Clarity & Density:** Carefully tuned information density preventing visual fatigue while maximizing viewport efficiency across various mobile form factors.

## Colors

The palette leverages an authoritative indigo paired with an electric blue accent to communicate dynamic speed and reliability. Slate grays ground the interface, avoiding harsh pitch blacks and stark whites in favor of nuanced, eye-friendly tones.

### Semantic & Functional Tones
- **Primary / Brand Action:** `#4F46E5` (Indigo 600) — Main active states, outbound interactive elements, primary CTAs.
- **Secondary / Electric Accent:** `#3B82F6` (Blue 500) — Outgoing message highlights, interactive links, active read receipt checkmarks.
- **Success / Online Status:** `#10B981` (Emerald 500) — Active contact presence rings, connected status badges.
- **Warning:** `#F59E0B` (Amber 500) — Network reconnection banners, ephemeral media timers.
- **Danger:** `#EF4444` (Red 500) — Destructive actions, call termination, blocked contact indicators.

### Theme Modes & Surface Tokens
- **Light Mode:**
  - Base Canvas (`surface`): `#F8FAFC` (Slate 50)
  - Surface Card / Input (`surface-container`): `#FFFFFF`
  - Incoming Bubble: `#F1F5F9` (Slate 100) with `#0F172A` text
  - Outgoing Bubble: Solid `#4F46E5` or linear gradient (`#4F46E5` to `#3B82F6`) with `#FFFFFF` text
  - Borders & Separators: `#E2E8F0` (Slate 200)
  - Text Primary: `#0F172A` (Slate 900)
  - Text Secondary: `#64748B` (Slate 500)
- **Dark Mode:**
  - Base Canvas (`surface`): `#0B0F19` (Deep Slate)
  - Surface Card / Input (`surface-container`): `#1E293B` (Slate 800)
  - Incoming Bubble: `#1E293B` (Slate 800) with `#F8FAFC` text
  - Outgoing Bubble: `#4F46E5` with `#FFFFFF` text
  - Borders & Separators: `#334155` (Slate 700)
  - Text Primary: `#F8FAFC` (Slate 50)
  - Text Secondary: `#94A3B8` (Slate 400)

## Typography

The type hierarchy uses **Inter** across all roles to ensure universal rendering, optimal letter spacing at tight sizes, and native alignment across Android and iOS platforms.

- **Legibility in Chat:** Message bodies prioritize a 15–16px baseline for standard communication to ensure effortless scanning under variable mobile lighting.
- **Timestamps & Badges:** `caption-sm` and `micro-badge` employ tightened tabular figures so delivery times and unread count badges maintain fixed geometry without horizontal jitter during dynamic updates.
- **Weights:** Restricted to Regular (400), Medium (500), Semi-Bold (600), and Bold (700). Ultra-thin and ultra-heavy weights are omitted to preserve clarity on dense message threads.

## Layout & Spacing

This design system uses a strict 8-point spatial foundation with 4-point half-step sub-increments for compact mobile interfaces.

### Grid & Canvas Structure
- **Mobile Fluid Flow:** Full-width adaptive canvas constrained within device safe areas (`SafeArea` / Status Bar / Home Indicator).
- **Horizontal Screen Padding:** `16px` (`margin`) across standard screens; `12px` inside conversational thread views to maximize bubble payload width.
- **Bubble Insets:** 
  - Internal bubble padding: `10px` vertical, `14px` horizontal.
  - Spacing between consecutive bubbles from the same sender: `4px` (`space-xs`).
  - Spacing between bubbles when sender changes: `12px` (`space-md`).
- **Input & Toolbars:** Composition bar fixed to bottom safe area with `8px` vertical cushion and `8px` horizontal item separation.

## Elevation & Depth

Visual depth is achieved through **tonal separation** and subtle **ambient shadows**, deliberately avoiding harsh drops that clutter message streams.

- **Level 0 (Canvas):** Flat base surface (`#F8FAFC` light / `#0B0F19` dark).
- **Level 1 (Card & Thread Tile):** Light mode: `0px 1px 2px rgba(15, 23, 42, 0.04)`. Dark mode: `#1E293B` without drop shadow, delimited by a 0.5px border (`#334155`).
- **Level 2 (Navigation / App Bar / Input Bar):** Frosted blur effect (backdrop filter `16px` blur) with 85% opacity surface overlay and a bottom border of `1px` solid (`#E2E8F0` / `#1E293B`).
- **Level 3 (Floating Action Button & Overlays):** `0px 8px 20px -4px rgba(79, 70, 229, 0.35)` to produce an active indigo ambient glow.
- **Level 4 (Modal Bottom Sheets):** `0px -8px 32px rgba(15, 23, 42, 0.12)`, anchored with rounded top corners.

## Shapes

The geometric identity balances organic curve treatments with structural efficiency:

- **Message Bubbles:** `16px` standard corner curvature. Grouped messages collapse the adjacent corner (trailing edge for outgoing, leading edge for incoming) to `4px` to visually chain connected communications.
- **Cards, Preview Modules & Modals:** `12px` to `16px` radius.
- **Interactive Badges & Meta Tags:** `8px` squircle curves for unread counts and status labels.
- **Pills & Circular Controls:** Action chips, search bars, composition pills, and quick filter triggers utilize a full continuous pill profile (`24px` to `9999px`).
- **Avatar Elements:** Strict circular shapes (`9999px`) accompanied by a 2px outer gap-border framing the emerald presence dot.

## Components

### Chat Bubbles
- **Outgoing (Self):**
  - Background: Primary Indigo gradient (`#4F46E5` to `#3B82F6`) or solid `#4F46E5`.
  - Content: Pure white body copy (`#FFFFFF`). Meta info (time + receipt status) displayed in 75% translucent white.
  - Tail behavior: Border radius `16px 16px 4px 16px` on the final bubble of an outbound burst.
- **Incoming (Counterpart):**
  - Background: Muted container (`#F1F5F9` in light, `#1E293B` in dark).
  - Content: Primary text (`#0F172A` in light, `#F8FAFC` in dark). Meta info in secondary slate (`#64748B`).
  - Tail behavior: Border radius `16px 16px 16px 4px` on the final bubble of an inbound burst.
- **Status Indicators:** Micro dual-check icon positioned inline with the timestamp. Single gray check (Sent), double gray check (Delivered), double electric blue (`#3B82F6`) check (Read).

### App Bar & Navigation
- **Top App Bar:** 
  - Height: `56px` excluding status bar.
  - Layout: Back navigation, leading avatar (`36px`) with presence indicator, thread title (Semi-Bold `16px`), subtitle (`12px` "online" or "last seen"), and trailing action icons (Voice, Video, Overflow Menu).
  - Background: Glassmorphic transluscent surface with blurred background bleed.
- **Bottom Navigation Bar:**
  - Height: `64px` with home indicator inset.
  - Active tab states highlighted with vibrant Indigo tint and an optional micro-dot beneath the active icon.
  - Inactive tabs rendered in Slate 400.

### Input Bar (Message Composer)
- **Container:** Rounded pill or soft box (`24px` radius) nesting voice memo triggers, attachment clip, dynamic textfield, and emoji picker button.
- **Action Button:** Transforms dynamically via spring transition from a microphone icon (voice recording) to a filled Indigo circular send button (`36px` circle) as text input is detected.

### Lists & Conversation Tiles
- **Thread Tile:** Height `72px`. Avatar (`48px`) on left with dynamic active indicator dot. Title and preview text stacked with auto-ellipsis. 
- **Right Meta Stack:** Formatted timestamp aligned top-right, paired with a vibrant Indigo unread badge pill (`minimum width 20px`, height `20px`, centered bold micro-text).

### Floating Action Button (FAB)
- Placed bottom-right (`16px` offset). Dimensions: `56px × 56px`. Full circle or rounded pill for "New Chat". 
- Indigo gradient background with glowing elevation shadow (`0px 8px 20px -4px rgba(79, 70, 229, 0.35)`).

### Bottom Sheet (Action Menus & Attachments)
- Presentation: Smooth slide-up transition anchored with a centered drag handle (`36px × 4px`, rounded, Slate 300).
- Surface: Rounded top corners (`20px`).
- Grid tiles for media selection (Gallery, Camera, Document, Location, Contact) formatted with soft background squares (`48px`, `12px` radius) and label underneath.