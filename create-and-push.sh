#!/usr/bin/env bash
set -euo pipefail

# Script para crear el esqueleto Next.js (TypeScript + Tailwind + ESLint + App Router + src dir + alias @/*)
# y hacer commit + push a la rama main.
#
# Uso:
#   ./create-and-push.sh           # crea archivos, npm install y push
#   ./create-and-push.sh --no-install   # crea archivos y push sin npm install
#
# IMPORTANTE: revisa el script antes de ejecutarlo. No comparte ni pide credenciales:
# usa las credenciales configuradas en tu máquina (SSH/PAT) para git push.

SKIP_INSTALL=false
for arg in "$@"; do
  case "$arg" in
    --no-install) SKIP_INSTALL=true ;;
    *) echo "Aviso: argumento desconocido: $arg" ;;
  esac
done

COMMIT_MSG='Inicializa Next.js con TypeScript, Tailwind, ESLint, App Router, src dir y alias @/*'
BRANCH=main
REMOTE=origin

# Comprueba que estamos dentro de un repo git
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "ERROR: No parece que estés dentro de un repositorio Git. Clona el repo y ejecuta desde la raíz."
  exit 1
fi

# Cambiar a main y actualizar
echo "Cambiando a rama ${BRANCH} y haciendo pull..."
git checkout "${BRANCH}"
git pull "${REMOTE}" "${BRANCH}" || true

# Crear estructura de carpetas
echo "Creando directorios..."
mkdir -p src/app src/styles

echo "Creando archivos..."

cat > package.json <<'EOF'
{ "name": "buki", "version": "0.1.0", "private": true, "scripts": { "dev": "next dev", "build": "next build", "start": "next start", "lint": "next lint" }, "dependencies": { "next": "14.0.0", "react": "18.2.0", "react-dom": "18.2.0" }, "devDependencies": { "typescript": "5.2.2", "tailwindcss": "3.5.2", "postcss": "8.4.21", "autoprefixer": "10.4.14", "eslint": "8.47.0", "eslint-config-next": "14.0.0" } }
EOF

cat > tsconfig.json <<'EOF'
{ "compilerOptions": { "target": "esnext", "lib": ["dom","dom.iterable","esnext"], "allowJs": false, "skipLibCheck": true, "strict": true, "forceConsistentCasingInFileNames": true, "noEmit": true, "esModuleInterop": true, "module": "esnext", "moduleResolution": "node", "resolveJsonModule": true, "isolatedModules": true, "jsx": "preserve", "incremental": true, "baseUrl": ".", "paths": { "@/*": ["src/*"] } }, "include": ["next-env.d.ts","**/*.ts","**/*.tsx"], "exclude": ["node_modules"] }
EOF

cat > next-env.d.ts <<'EOF'
/// <reference types="next" />
/// <reference types="next/types/global" />
EOF

cat > next.config.js <<'EOF'
/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
  experimental: { appDir: true }
}
module.exports = nextConfig
EOF

cat > postcss.config.cjs <<'EOF'
module.exports = { plugins: { tailwindcss: {}, autoprefixer: {} } }
EOF

cat > tailwind.config.cjs <<'EOF'
module.exports = { content: ["./src/**/*.{js,ts,jsx,tsx,mdx}"], theme: { extend: {} }, plugins: [] }
EOF

cat > .eslintrc.json <<'EOF'
{ "extends": "next/core-web-vitals", "rules": {} }
EOF

cat > .gitignore <<'EOF'
/node_modules
/.next
/.next/cache
.env.local
.env.*.local
.DS_Store
npm-debug.log*
yarn-debug.log*
yarn-error.log*
EOF

cat > src/app/layout.tsx <<'EOF'
import './globals.css'
import { ReactNode } from 'react'
export const metadata = { title: 'Buki', description: 'Buki - App' }
export default function RootLayout({ children }: { children: ReactNode }) {
  return ( <html lang="en"><body>{children}</body></html> )
}
EOF

cat > src/app/page.tsx <<'EOF'
export default function Home() {
  return (
    <main className="min-h-screen flex items-center justify-center p-8">
      <div>
        <h1 className="text-4xl font-bold">Bienvenido a Buki</h1>
        <p className="mt-4 text-gray-600">Aplicación inicializada con Next.js, TypeScript y Tailwind.</p>
      </div>
    </main>
  )
}
EOF

cat > src/styles/globals.css <<'EOF'
@tailwind base;
@tailwind components;
@tailwind utilities;
html, body, #__next { height: 100%; }
body { @apply bg-white text-slate-900; margin: 0; font-family: system-ui, -apple-system, 'Segoe UI', Roboto, 'Helvetica Neue', Arial; }
EOF

cat > README.md <<'EOF'
# BUKI
Esqueleto inicial creado para Next.js con TypeScript, Tailwind CSS, ESLint, App Router y estructura en `src/`.
EOF

echo "Archivos preparados."
if [ "${SKIP_INSTALL}" = false ]; then
  if command -v npm >/dev/null 2>&1; then
    npm install
  else
    echo "npm no encontrado: omitiendo instalación."
  fi
fi

git add .
if git diff --cached --quiet; then
  echo "No hay cambios para commitear."
else
  git commit -m "$COMMIT_MSG"
fi
git push "${REMOTE}" "${BRANCH}"
echo "Listo."
