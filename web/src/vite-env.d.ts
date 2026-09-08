/// <reference types="vite/client" />

interface ImportMetaEnv {
  readonly VITE_CHAIN_ID?: string
  readonly VITE_RPC_URL?: string
  readonly VITE_USDG_ADDRESS?: string
  readonly VITE_ARENA_ADDRESS?: string
  readonly VITE_RACE_ADDRESS?: string
  readonly VITE_PONS_FACTORY?: string
}

interface ImportMeta {
  readonly env: ImportMetaEnv
}
