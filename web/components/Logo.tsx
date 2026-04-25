import { brand } from "@/content/site";

/**
 * Pure-CSS logo mark — gradient-filled rounded square with a stylized
 * sparkle/sweep cut in white. Matches the prototype's logo-mark CSS shape.
 */
export function LogoMark({ size = 28 }: { size?: number }) {
  return (
    <span
      aria-hidden
      className="relative inline-block shrink-0"
      style={{
        width: size,
        height: size,
        borderRadius: 8,
        background: "var(--accent-grad)",
        boxShadow: "0 6px 18px -6px rgba(124,92,255,0.7)",
      }}
    >
      <span
        style={{
          position: "absolute",
          left: size * 0.29,
          top: size * 0.39,
          width: size * 0.43,
          height: 2,
          borderRadius: 1.5,
          background: "rgba(255,255,255,0.92)",
          transform: "rotate(45deg)",
        }}
      />
      <span
        style={{
          position: "absolute",
          left: size * 0.43,
          top: size * 0.57,
          width: size * 0.28,
          height: 2,
          borderRadius: 1.5,
          background: "rgba(255,255,255,0.92)",
          transform: "rotate(45deg)",
        }}
      />
    </span>
  );
}

export function LogoLockup() {
  return (
    <div className="flex items-center gap-2.5 font-semibold tracking-tight">
      <LogoMark size={28} />
      <span>{brand.name}</span>
    </div>
  );
}
