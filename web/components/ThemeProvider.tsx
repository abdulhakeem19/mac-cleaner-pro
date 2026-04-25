"use client";

import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useState,
  type ReactNode,
} from "react";

export type Theme = "light" | "dark";
const STORAGE_KEY = "mcp.theme";

type Ctx = {
  theme: Theme;
  setTheme: (t: Theme) => void;
  toggle: () => void;
};

const ThemeContext = createContext<Ctx | null>(null);

/**
 * Minimal theme manager: reads `data-theme` from <html> (set by the inline boot
 * script in layout.tsx to avoid FOUC), keeps state in sync, persists to localStorage.
 *
 * Default at first paint = system preference. Once the user picks one explicitly
 * we persist that choice.
 */
export function ThemeProvider({ children }: { children: ReactNode }) {
  const [theme, setThemeState] = useState<Theme>("dark");

  useEffect(() => {
    const initial =
      (document.documentElement.dataset.theme as Theme | undefined) ?? "dark";
    setThemeState(initial);
  }, []);

  const setTheme = useCallback((t: Theme) => {
    setThemeState(t);
    document.documentElement.dataset.theme = t;
    try {
      window.localStorage.setItem(STORAGE_KEY, t);
    } catch {}
  }, []);

  const toggle = useCallback(() => {
    setTheme(theme === "dark" ? "light" : "dark");
  }, [theme, setTheme]);

  return (
    <ThemeContext.Provider value={{ theme, setTheme, toggle }}>
      {children}
    </ThemeContext.Provider>
  );
}

export function useTheme() {
  const ctx = useContext(ThemeContext);
  if (!ctx) throw new Error("useTheme must be used inside ThemeProvider");
  return ctx;
}

/**
 * Inline boot script — must run before React hydrates so the user never sees a
 * flash of the wrong theme. Reads stored choice or system preference and sets
 * `<html data-theme="...">` synchronously.
 */
export const themeBootScript = `(function(){try{
  var k='${STORAGE_KEY}';
  var t=localStorage.getItem(k);
  if(t!=='light'&&t!=='dark'){
    t=window.matchMedia('(prefers-color-scheme: light)').matches?'light':'dark';
  }
  document.documentElement.dataset.theme=t;
}catch(e){document.documentElement.dataset.theme='dark';}})();`;
