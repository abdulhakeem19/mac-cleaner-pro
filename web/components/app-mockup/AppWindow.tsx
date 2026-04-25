import type { ReactNode } from "react";

/**
 * macOS window chrome (traffic lights + centered title) wrapping arbitrary
 * content. Used by the hero, the SpaceLens tease, and other dashboards.
 */
export function AppWindow({
  title,
  height,
  children,
}: {
  title: string;
  height?: number;
  children: ReactNode;
}) {
  return (
    <div className="app-window">
      <div className="app-titlebar">
        <div className="traffic">
          <span />
          <span />
          <span />
        </div>
        <div className="titlebar-title">{title}</div>
        <span style={{ width: 52 }} />
      </div>
      <div style={{ height, overflow: "hidden" }}>{children}</div>
    </div>
  );
}
