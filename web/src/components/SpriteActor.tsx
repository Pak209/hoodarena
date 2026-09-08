import { useEffect, useMemo, useState } from 'react'
import type { MatchAnim } from '../lib/matchSim'

const FRAME_PX = 96
const SHEET_W = 384
const SHEET_H = 96

const FRAME_INDEX: Record<MatchAnim, number> = {
  idle: 0,
  run: 1,
  action: 2,
  celebrate: 3,
}

export interface SpriteActorProps {
  slug?: string
  anim: MatchAnim
  name?: string
  /** Static portrait fallback when sheet missing / onerror */
  fallbackArt?: string
  size?: number
  /** Light idle↔run step while playing */
  playing?: boolean
}

/**
 * Kit AF 4×1 pixel sheet: idle | run | action | celebrate
 * Path: /art/sprites/{slug}.png · each frame 96×96 · sheet 384×96
 */
export function SpriteActor({
  slug,
  anim,
  name,
  fallbackArt,
  size = FRAME_PX,
  playing = false,
}: SpriteActorProps) {
  const [sheetOk, setSheetOk] = useState(false)
  const [step, setStep] = useState(0)

  const sheetSrc = slug ? `/art/sprites/${slug}.png` : undefined

  useEffect(() => {
    if (!sheetSrc) {
      setSheetOk(false)
      return
    }
    let cancelled = false
    setSheetOk(false)
    const img = new Image()
    img.onload = () => {
      if (!cancelled) setSheetOk(true)
    }
    img.onerror = () => {
      if (!cancelled) setSheetOk(false)
    }
    img.src = sheetSrc
    return () => {
      cancelled = true
    }
  }, [sheetSrc])

  useEffect(() => {
    if (!playing || anim !== 'run' || !sheetOk) {
      setStep(0)
      return
    }
    const id = window.setInterval(() => {
      setStep((s) => (s === 0 ? 1 : 0))
    }, 280)
    return () => window.clearInterval(id)
  }, [playing, anim, sheetOk])

  const frameAnim: MatchAnim =
    playing && anim === 'run' ? (step === 0 ? 'run' : 'idle') : anim
  const frame = FRAME_INDEX[frameAnim]

  const scale = size / FRAME_PX
  const style = useMemo(() => {
    if (!sheetOk || !sheetSrc) return undefined
    return {
      width: FRAME_PX,
      height: FRAME_PX,
      backgroundImage: `url(${sheetSrc})`,
      backgroundRepeat: 'no-repeat' as const,
      backgroundSize: `${SHEET_W}px ${SHEET_H}px`,
      backgroundPosition: `-${frame * FRAME_PX}px 0`,
      transform: scale !== 1 ? `scale(${scale})` : undefined,
      transformOrigin: 'top left' as const,
    }
  }, [sheetOk, sheetSrc, frame, scale])

  const label = name ?? slug ?? 'rival'

  if (!slug) {
    return (
      <div
        className="sprite-actor sprite-actor-placeholder"
        style={{ width: size, height: size }}
        title="Rival"
        aria-label="Rival silhouette"
      >
        <div className="sprite-frame sprite-frame-muted" />
      </div>
    )
  }

  if (!sheetOk) {
    return (
      <div
        className="sprite-actor sprite-actor-fallback"
        style={{ width: size, height: size }}
        title={label}
        aria-label={label}
      >
        {fallbackArt ? (
          <img
            className="sprite-fallback-art"
            src={fallbackArt}
            alt=""
            width={size}
            height={size}
            onError={(e) => {
              ;(e.currentTarget as HTMLImageElement).style.visibility = 'hidden'
            }}
          />
        ) : (
          <div className="sprite-frame sprite-frame-muted" />
        )}
      </div>
    )
  }

  return (
    <div
      className="sprite-actor"
      style={{ width: size, height: size }}
      title={`${label} · ${frameAnim}`}
      aria-label={`${label} ${frameAnim}`}
    >
      <div className="sprite-frame" style={style} />
    </div>
  )
}
