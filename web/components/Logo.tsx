import { brand } from "@/content/site";

export function AppleLogo({ size = 16, className }: { size?: number; className?: string }) {
  return (
    <svg
      aria-hidden
      width={size}
      height={size}
      viewBox="0 0 24 24"
      fill="currentColor"
      className={className}
      xmlns="http://www.w3.org/2000/svg"
    >
      <path d="M12.152 6.896c-.948 0-2.415-1.078-3.96-1.04-2.04.027-3.91 1.183-4.961 3.014-2.117 3.675-.54 9.103 1.519 12.09 1.013 1.454 2.208 3.09 3.792 3.029 1.52-.065 2.09-.987 3.935-.987 1.831 0 2.35.987 3.96.948 1.637-.026 2.676-1.48 3.676-2.948 1.156-1.688 1.636-3.325 1.662-3.415-.039-.013-3.182-1.221-3.22-4.857-.026-3.04 2.48-4.494 2.597-4.559-1.429-2.09-3.623-2.324-4.39-2.376-2-.156-3.675 1.09-4.61 1.09zM15.53 3.83c.843-1.012 1.4-2.427 1.245-3.83-1.207.052-2.662.805-3.532 1.818-.78.896-1.454 2.338-1.273 3.714 1.338.104 2.715-.688 3.559-1.701z" />
    </svg>
  );
}

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
