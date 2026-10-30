# Compact macro-energy tooltip references

Research date: 2026-10-30. Scope: resources and design recommendations; no app changes.

## Verified primary references

- [shadcn/ui Chart — Tooltip](https://ui.shadcn.com/docs/components/base/chart#tooltip): chart tooltips compose an indicator, name and value; the heading can be hidden and the indicator can be a dot. Chart colors come from the chart configuration, keeping the legend consistent with its series.
- [shadcn/ui chart source](https://github.com/shadcn-ui/ui/blob/main/apps/v4/registry/new-york-v4/ui/chart.tsx): `ChartTooltipContent` uses compact text, a subtle border, rounded corners and shadow. Its rows pair muted names with right-aligned numeric values using tabular figures. The current source specifies 10px horizontal/6px vertical padding, 6px row gaps, 12px text and 8px corners through the default Tailwind spacing scale. These are reference dimensions, not Flutter requirements.
- [Flutter Tooltip API](https://api.flutter.dev/flutter/material/Tooltip-class.html): the existing native widget supports `richMessage` with `WidgetSpan`, decoration, tap triggers, automatic dismissal with `showDuration`, and proximity controls through `preferBelow` and `verticalOffset`. Flutter recommends placement above a trigger when that avoids covering the content with a finger or pointer.

## Recommendation for AtlasTracker

Design interpretation based on the references and the user's requested content:

- Keep exactly three rows: colored circular dot, macro name, percentage. Omit heading, grams, calories, footer and close button.
- Use content-sized width with a modest maximum rather than a broad fixed card. Retain wrapping for long translations or enlarged text.
- Start with 10px horizontal/8px vertical padding, 6px row gaps, 7px dots and 10–12px corners. Keep text around 12px with system text scaling enabled.
- Give labels a secondary text color and percentages a stronger weight with tabular figures, aligned to the trailing edge. Keep the existing orange/green/blue series colors.
- Use a neutral theme-aware surface, a fine low-contrast border and one restrained shadow. The small, disciplined layout provides the modern chart-tooltip appearance; no new UI library is needed.
- Keep tap activation and the existing four-second dismissal. Place the tooltip close above the bar, allowing native viewport collision handling. Keep the Journal's details collapsed by default.

The specific dimensions and four-second duration are product choices, not universal requirements of the cited systems. Validate at 320px width, text scale 1.5, both themes, and with an empty day before shipping an implementation.

## Access notes

Carbon's component usage page and Material 3's interactive overview were not reliably readable through this browsing tool. They were not used to substantiate the styling recommendations above. The directly inspected shadcn source and Flutter API are sufficient for the proposed approach.
