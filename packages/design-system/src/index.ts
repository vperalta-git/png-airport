/**
 * PNG Airport Ground Transportation & Security Operations Design System
 * High-contrast, aviation-operational theme tailored for field visibility and high-trust enterprise travel.
 */

export const colors = {
  // Primary Aviation Brand
  navy: {
    900: '#07101E',
    800: '#0B192C',
    700: '#152943',
    600: '#1E3A5F',
  },
  gold: {
    500: '#D4AF37',
    400: '#E5C158',
    600: '#B89726',
  },
  // Operational Status Colors
  status: {
    confirmed: '#2563EB',     // Blue
    dispatched: '#0284C7',    // Sky
    en_route: '#D97706',      // Amber
    at_airport: '#7C3AED',    // Purple
    verified: '#059669',      // Emerald
    in_transit: '#2563EB',    // Blue
    completed: '#10B981',     // Green
    incident: '#DC2626',      // Red
    cancelled: '#6B7280',     // Gray
  },
  // Neutrals & Surfaces
  surface: {
    background: '#0B1320',
    card: '#131F33',
    cardBorder: '#1E2F4D',
    inputBg: '#0F1A2B',
    modalOverlay: 'rgba(0, 0, 0, 0.75)',
  },
  text: {
    primary: '#FFFFFF',
    secondary: '#94A3B8',
    muted: '#64748B',
    accent: '#D4AF37',
    danger: '#F87171',
    success: '#34D399',
  },
};

export const typography = {
  titleLarge: {
    fontSize: 24,
    fontWeight: '700' as const,
    letterSpacing: 0.2,
  },
  titleMedium: {
    fontSize: 20,
    fontWeight: '600' as const,
  },
  body: {
    fontSize: 15,
    fontWeight: '400' as const,
    lineHeight: 22,
  },
  caption: {
    fontSize: 12,
    fontWeight: '500' as const,
    letterSpacing: 0.3,
  },
  actionLarge: {
    fontSize: 17,
    fontWeight: '700' as const,
    textTransform: 'uppercase' as const,
    letterSpacing: 0.5,
  },
};

export const spacing = {
  xs: 4,
  sm: 8,
  md: 16,
  lg: 24,
  xl: 32,
  xxl: 48,
};

export const radii = {
  sm: 6,
  md: 10,
  lg: 16,
  full: 9999,
};
