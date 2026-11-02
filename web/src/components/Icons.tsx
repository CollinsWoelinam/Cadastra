// Stroke icons used across the portal; decorative unless given a label by the caller.
type IconProps = { size?: number; color?: string; strokeWidth?: number };

function Svg({ size = 18, color = "currentColor", strokeWidth = 2, children }: IconProps & { children: React.ReactNode }) {
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke={color} strokeWidth={strokeWidth}
         strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
      {children}
    </svg>
  );
}

export const BrandMark = ({ size = 28, ring = "#E0A526" }: { size?: number; ring?: string }) => (
  <svg width={size} height={size} viewBox="0 0 28 28" aria-hidden="true">
    <rect x="4" y="4" width="20" height="20" rx="3" fill="none" stroke={ring} strokeWidth="2.2" transform="rotate(45 14 14)" />
    <circle cx="14" cy="14" r="3.2" fill="#E0A526" />
  </svg>
);

export const SearchIcon = (p: IconProps) => <Svg {...p}><circle cx="11" cy="11" r="7" /><path d="M20 20l-3.5-3.5" /></Svg>;
export const PlusIcon = (p: IconProps) => <Svg {...p}><path d="M12 5v14M5 12h14" /></Svg>;
export const MinusIcon = (p: IconProps) => <Svg {...p}><path d="M5 12h14" /></Svg>;
export const FitIcon = (p: IconProps) => <Svg {...p}><path d="M4 9V4h5M15 4h5v5M20 15v5h-5M9 20H4v-5" /></Svg>;
export const CheckIcon = (p: IconProps) => <Svg {...p}><path d="M5 12.5l4.5 4.5L19 7.5" /></Svg>;
export const CheckCircleIcon = (p: IconProps) => <Svg {...p}><circle cx="12" cy="12" r="9" /><path d="M8 12l3 3 5-6" /></Svg>;
export const DownloadIcon = (p: IconProps) => <Svg {...p}><path d="M12 4v11M7 10l5 5 5-5M5 20h14" /></Svg>;
export const WarningIcon = (p: IconProps) => <Svg {...p}><path d="M12 3l9 16H3z" /><path d="M12 10v4M12 17.5v.5" /></Svg>;
export const InfoIcon = (p: IconProps) => <Svg {...p}><circle cx="12" cy="12" r="9" /><path d="M12 7v6M12 16.5v.5" /></Svg>;
export const ArrowRightIcon = (p: IconProps) => <Svg {...p}><path d="M5 12h14M13 6l6 6-6 6" /></Svg>;
export const EyeIcon = (p: IconProps) => <Svg {...p}><path d="M2 12s3.5-7 10-7 10 7 10 7-3.5 7-10 7S2 12 2 12z" /><circle cx="12" cy="12" r="3" /></Svg>;
export const EyeOffIcon = (p: IconProps) => <Svg {...p}><path d="M3 3l18 18M10.6 5.1A10 10 0 0 1 12 5c6.5 0 10 7 10 7a17 17 0 0 1-3.2 4M6.6 6.6A17 17 0 0 0 2 12s3.5 7 10 7a9.6 9.6 0 0 0 5.4-1.6" /><path d="M9.9 9.9a3 3 0 0 0 4.2 4.2" /></Svg>;
export const QrIcon = (p: IconProps) => <Svg {...p}><rect x="4" y="4" width="16" height="16" rx="2" /><path d="M8 8h3v3H8zM13 13h3v3h-3zM13 8h3M8 16h3" /></Svg>;
