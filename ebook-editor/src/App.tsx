import React, { useCallback, useEffect, useMemo, useRef, useState } from 'react'
import { useEditor, EditorContent } from '@tiptap/react'
import StarterKit from '@tiptap/starter-kit'
import Link from '@tiptap/extension-link'
import Placeholder from '@tiptap/extension-placeholder'
import debounce from 'lodash.debounce'
import Underline from '@tiptap/extension-underline'
import Highlight from '@tiptap/extension-highlight'
import Superscript from '@tiptap/extension-superscript'
import Subscript from '@tiptap/extension-subscript'
import TextAlign from '@tiptap/extension-text-align'
import Image from '@tiptap/extension-image'
import TaskList from '@tiptap/extension-task-list'
import TaskItem from '@tiptap/extension-task-item'

import axios from 'axios'
import { ConfirmDialog, Modal } from './components/Modal'
import PendingModal from './components/PendingModal'

const API_BASE = (import.meta as any).env?.VITE_API_BASE || 'https://device-api.expotoworld.com'
import Login from './Login'
import Toolbar from './Toolbar'
import WordCount from './WordCount'
import { ThemeProvider, useThemeMode } from './theme'
import './i18n'
import { useTranslation } from 'react-i18next'
import { AUTH_BASE, getRefreshToken, setAccessToken, setRefreshToken, clearTokens } from './auth'
import { MediaDeletionExtension, deleteMediaFromS3 } from './MediaDeletionExtension'
import { VideoNode } from './nodes/VideoNode'
import { AudioNode } from './nodes/AudioNode'
import VersionHistorySidebar from './components/VersionHistorySidebar'
import OutlineSidebar from './components/OutlineSidebar'
import { HeadingWithId } from './extensions/HeadingWithId'
import { InternalLinkNavigation } from './extensions/InternalLinkNavigation'

function UserMenu({ onLogout, token }: { onLogout: () => void; token: string | null }) {
  const { t } = useTranslation()
  const [open, setOpen] = useState(false)
  const menuRef = useRef<HTMLDivElement>(null)

  const [pendingOpen, setPendingOpen] = useState(false)
  const [confirmOpen, setConfirmOpen] = useState(false)
  const [resultMsg, setResultMsg] = useState<string | null>(null)

  const headers = useMemo(() => (token ? { Authorization: `Bearer ${token}` } : {}), [token])

  useEffect(() => {
    const handleClickOutside = (event: MouseEvent) => {
      if (menuRef.current && !menuRef.current.contains(event.target as Node)) {
        setOpen(false)
      }
    }
    if (open) {
      document.addEventListener('mousedown', handleClickOutside)
      return () => document.removeEventListener('mousedown', handleClickOutside)
    }
  }, [open])

  return (
    <div className="dropdown" ref={menuRef} style={{ position: 'relative' }}>
      <button
        className="theme-toggle"
        onClick={() => setOpen(v => !v)}
        data-tooltip={t('user.menu_tooltip')}
        aria-label={t('user.menu_tooltip')}
        type="button"
      >
        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor" aria-hidden>
          <path d="M12 2C17.5228 2 22 6.47715 22 12C22 17.5228 17.5228 22 12 22C6.47715 22 2 17.5228 2 12C2 6.47715 6.47715 2 12 2ZM12.1597 16C10.1243 16 8.29182 16.8687 7.01276 18.2556C8.38039 19.3474 10.114 20 12 20C13.9695 20 15.7727 19.2883 17.1666 18.1081C15.8956 16.8074 14.1219 16 12.1597 16ZM12 4C7.58172 4 4 7.58172 4 12C4 13.8106 4.6015 15.4807 5.61557 16.8214C7.25639 15.0841 9.58144 14 12.1597 14C14.6441 14 16.8933 15.0066 18.5218 16.6342C19.4526 15.3267 20 13.7273 20 12C20 7.58172 16.4183 4 12 4ZM12 5C14.2091 5 16 6.79086 16 9C16 11.2091 14.2091 13 12 13C9.79086 13 8 11.2091 8 9C8 6.79086 9.79086 5 12 5ZM12 7C10.8954 7 10 7.89543 10 9C10 10.1046 10.8954 11 12 11C13.1046 11 14 10.1046 14 9C14 7.89543 13.1046 7 12 7Z"/>
        </svg>
      </button>
      {open && (
        <div className="dropdown-menu" role="menu" style={{ right: 0, left: 'auto', minWidth: '150px' }}>
          <button
            className="dropdown-item"
            onClick={() => { onLogout(); setOpen(false); }}
            style={{ display: 'flex', alignItems: 'center', gap: '8px', width: '100%', padding: '8px 12px' }}
          >
            <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor" style={{ width: '18px', height: '18px' }}>
              <path d="M4 18H6V20H18V4H6V6H4V3C4 2.44772 4.44772 2 5 2H19C19.5523 2 20 2.44772 20 3V21C20 21.5523 19.5523 22 19 22H5C4.44772 22 4 21.5523 4 21V18ZM6 11H13V13H6V16L1 12L6 8V11Z"/>
            </svg>
            {t('user.logout')}
          </button>
          <button
            className="dropdown-item"
            onClick={() => { setOpen(false); setConfirmOpen(true) }}
            style={{ display: 'flex', alignItems: 'center', gap: '8px', width: '100%', padding: '8px 12px' }}
          >
            <svg className="miw-ico" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor" style={{ width: '18px', height: '18px' }}>
              <path d="M3.08697 9H20.9134C21.4657 9 21.9134 9.44772 21.9134 10C21.9134 10.0277 21.9122 10.0554 21.9099 10.083L21.0766 20.083C21.0334 20.6013 20.6001 21 20.08 21H3.9203C3.40021 21 2.96695 20.6013 2.92376 20.083L2.09042 10.083C2.04456 9.53267 2.45355 9.04932 3.00392 9.00345C3.03155 9.00115 3.05925 9 3.08697 9ZM4.84044 19H19.1599L19.8266 11H4.17377L4.84044 19ZM13.4144 5H20.0002C20.5525 5 21.0002 5.44772 21.0002 6V7H3.00017V4C3.00017 3.44772 3.44789 3 4.00017 3H11.4144L13.4144 5Z"></path>
            </svg>
            <span>{t('version.reindex')}</span>
          </button>
          <button
            className="dropdown-item"
            onClick={() => { setOpen(false); setPendingOpen(true) }}
            style={{ display: 'flex', alignItems: 'center', gap: '8px', width: '100%', padding: '8px 12px' }}
          >
            <svg className="miw-ico" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor" style={{ width: '18px', height: '18px' }}>
              <path d="M20 7V20C20 21.1046 19.1046 22 18 22H6C4.89543 22 4 21.1046 4 20V7H2V5H22V7H20ZM6 7V20H18V7H6ZM11 9H13V11H11V9ZM11 12H13V14H11V12ZM11 15H13V17H11V15ZM7 2H17V4H7V2Z"></path>
            </svg>
            <span>{t('version.pending')}</span>
          </button>
        </div>
      )}
      <ConfirmDialog
        open={confirmOpen}
        title={t('version.reindexDialog.title')}
        message={t('version.reindexDialog.message')}
        confirmText={t('version.reindexDialog.confirm') || t('common.confirm')}
        cancelText={t('version.reindexDialog.cancel') || t('common.cancel')}
        onCancel={() => setConfirmOpen(false)}
        onConfirm={async () => {
          setConfirmOpen(false)
          try {
            await axios.post(`${API_BASE}/api/ebook/admin/reindex`, null, { headers })
            setResultMsg(t('version.reindexStatus.success'))
          } catch (e) { setResultMsg(t('version.reindexStatus.fail')) }
        }}
      />
      <Modal open={!!resultMsg} title={t('version.statusTitle')} onClose={() => setResultMsg(null)}>
        <div>{resultMsg}</div>
      </Modal>
      <PendingModal token={token} open={pendingOpen} onClose={() => setPendingOpen(false)} />
    </div>
  )
}

function useSaving() {
  const [status, setStatus] = useState<'idle'|'saving'|'saved'|'error'>('idle')
  const [lastSavedAt, setLastSavedAt] = useState<Date | null>(null)
  const markSaving = () => setStatus('saving')
  const markSaved = () => { setStatus('saved'); setLastSavedAt(new Date()) }
  const markError = () => setStatus('error')
  return { status, lastSavedAt, markSaving, markSaved, markError }
}

function Shell({ children, status, lastSavedAt, toolbar, actionsRight, afterUserMenu, token }: React.PropsWithChildren<{ status: string; lastSavedAt: Date | null; toolbar: React.ReactNode; actionsRight?: React.ReactNode; afterUserMenu?: React.ReactNode; token?: string | null }>) {
  const { mode, setMode } = useThemeMode()
  const { t, i18n } = useTranslation()
  return (
    <div className="editor-app">
      <div className="editor-header">
        <div className="editor-topbar">
          <div className="topbar-left">
            {toolbar}
          </div>
          <div className="topbar-right">
            <span className={`status-badge ${status === 'error' ? 'error' : status === 'saved' ? 'success' : ''}`}>
              {status === 'saving' && t('status.saving')}
              {status === 'saved' && t('status.saved_at', { time: lastSavedAt ? lastSavedAt.toLocaleTimeString() : '' })}
              {status === 'error' && t('status.save_failed')}
            </span>
            {actionsRight}
            <button
              className="theme-toggle lang-toggle"
              onClick={() => { const next = i18n.language === 'zh' ? 'en' : 'zh'; i18n.changeLanguage(next); try { localStorage.setItem('lang', next) } catch {} }}
              aria-label="Toggle language"
            >
              {i18n.language === 'zh' ? 'EN' : '中文'}
            </button>
            <button className="theme-toggle" onClick={() => setMode(mode === 'light' ? 'dark' : 'light')} aria-label="Toggle theme">
              {mode === 'light' ? (
                <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor" aria-hidden>
                  <path d="M10 6C10 10.4183 13.5817 14 18 14C19.4386 14 20.7885 13.6203 21.9549 12.9556C21.4738 18.0302 17.2005 22 12 22C6.47715 22 2 17.5228 2 12C2 6.79948 5.9698 2.52616 11.0444 2.04507C10.3797 3.21152 10 4.56142 10 6ZM4 12C4 16.4183 7.58172 20 12 20C14.9654 20 17.5757 18.3788 18.9571 15.9546C18.6407 15.9848 18.3214 16 18 16C12.4772 16 8 11.5228 8 6C8 5.67863 8.01524 5.35933 8.04536 5.04293C5.62119 6.42426 4 9.03458 4 12ZM18.1642 2.29104L19 2.5V3.5L18.1642 3.70896C17.4476 3.8881 16.8881 4.4476 16.709 5.16417L16.5 6H15.5L15.291 5.16417C15.1119 4.4476 14.5524 3.8881 13.8358 3.70896L13 3.5V2.5L13.8358 2.29104C14.5524 2.1119 15.1119 1.5524 15.291 0.835829L15.5 0H16.5L16.709 0.835829C16.8881 1.5524 17.4476 2.1119 18.1642 2.29104ZM23.1642 7.29104L24 7.5V8.5L23.1642 8.70896C22.4476 8.8881 21.8881 9.4476 21.709 10.1642L21.5 11H20.5L20.291 10.1642C20.1119 9.4476 19.5524 8.8881 18.8358 8.70896L18 8.5V7.5L18.8358 7.29104C19.5524 7.1119 20.1119 6.5524 20.291 5.83583L20.5 5H21.5L21.709 5.83583C21.8881 6.5524 22.4476 7.1119 23.1642 7.29104Z"/>
                </svg>
              ) : (
                <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor" aria-hidden>
                  <path d="M12 18C8.68629 18 6 15.3137 6 12C6 8.68629 8.68629 6 12 6C15.3137 6 18 8.68629 18 12C18 15.3137 15.3137 18 12 18ZM12 16C14.2091 16 16 14.2091 16 12C16 9.79086 14.2091 8 12 8C9.79086 8 8 9.79086 8 12C8 14.2091 9.79086 16 12 16ZM11 1H13V4H11V1ZM11 20H13V23H11V20ZM3.51472 4.92893L4.92893 3.51472L7.05025 5.63604L5.63604 7.05025L3.51472 4.92893ZM16.9497 18.364L18.364 16.9497L20.4853 19.0711L19.0711 20.4853L16.9497 18.364ZM19.0711 3.51472L20.4853 4.92893L18.364 7.05025L16.9497 5.63604L19.0711 3.51472ZM5.63604 16.9497L7.05025 18.364L4.92893 20.4853L3.51472 19.0711L5.63604 16.9497ZM23 11V13H20V11H23ZM4 11V13H1V11H4Z"/>
                </svg>
              )}
            </button>
            <UserMenu token={token} onLogout={() => {
              clearTokens(); // Clear both access and refresh tokens
              localStorage.removeItem('token'); // Clear old token key if exists
              delete axios.defaults.headers.common['Authorization']; // Remove auth header
              // Force immediate page reload to show login page
              window.location.reload();
            }} />
            {afterUserMenu}
          </div>
        </div>
      </div>
      <div className="editor-container">
        {children}
      </div>
    </div>
  )
}

export default function App() {
  const { status, lastSavedAt, markSaving, markSaved, markError } = useSaving()
  const [zoomLevel, setZoomLevel] = useState<number>(1)
  const [token, setToken] = useState<string | null>(null)
  const [authBoot, setAuthBoot] = useState<boolean>(true)
  const [versionsOpen, setVersionsOpen] = useState(false)
  const [outlineOpen, setOutlineOpen] = useState(false)
  const [saveOpen, setSaveOpen] = useState(false)
  const [saveName, setSaveName] = useState('')
  const toastTimer = useRef<number | null>(null)
  const [toastMsg, setToastMsg] = useState<string | null>(null)
  const [toastType, setToastType] = useState<'success'|'error'|'warn'|'info'>('info')
  const [toastVisible, setToastVisible] = useState(false)
  useEffect(() => {
    const onToast = (e: any) => {
      const msg = e?.detail?.message || String(e?.detail || '') || 'Notice'
      const type = (e?.detail?.type || e?.detail?.variant || 'info') as 'success'|'error'|'warn'|'info'
      setToastMsg(msg)
      setToastType(type)
      setToastVisible(true)
      if (toastTimer.current) window.clearTimeout(toastTimer.current as any)
      toastTimer.current = window.setTimeout(() => setToastVisible(false), 2500) as any
    }
    window.addEventListener('miw:toast' as any, onToast as any)
    return () => window.removeEventListener('miw:toast' as any, onToast as any)
  }, [])

  useEffect(() => {
    (async () => {
      try {
        const stored = (() => { try { return JSON.parse(localStorage.getItem('ebook_token') || 'null') } catch { return null } })()
        const tok = stored?.token as string | undefined
        const exp = stored?.expires_at ? new Date(stored.expires_at as string).getTime() : null
        if (tok && exp && exp - Date.now() > 5000) {
          setToken(tok)
          return
        }
        const rt = getRefreshToken()
        if (rt) {
          try {
            const res = await axios.post(`${AUTH_BASE}/api/auth/token/refresh`, { refresh_token: rt, rotate: false })
            const newTok = res.data?.token as string | undefined
            const tokenExp = res.data?.expires_at as string | undefined
            const newRt = res.data?.refresh_token as string | undefined
            const newRtExp = res.data?.refresh_expires_at as string | undefined
            if (newTok) {
              setAccessToken(newTok, tokenExp)
              if (newRt && newRtExp) setRefreshToken(newRt, newRtExp)
              setToken(newTok)
              return
            }
          } catch {}
        }
      } finally {
        setAuthBoot(false)
      }
    })()
  }, [])

  const saveDraft = useCallback(async (json: any) => {
    if (!token) return
    markSaving()
    try {
      await axios.put(`${API_BASE}/api/ebook`, json, { headers: { Authorization: `Bearer ${token}` } })
      markSaved()
    } catch (e) {
      console.error(e)
      // Do not force logout on first 401; interceptors will attempt silent refresh and retry.
      // If refresh truly fails, subsequent calls will still fail and the user can reauthenticate.
      markError()
    }
  }, [token])

  const debouncedSave = useMemo(() => debounce(saveDraft, 2000), [saveDraft])

  const saveRef = useRef(debouncedSave)
  useEffect(() => { saveRef.current = debouncedSave; return () => debouncedSave.cancel?.() }, [debouncedSave])

  const { t } = useTranslation()

  const editor = useEditor({
    extensions: [
      StarterKit.configure({ codeBlock: false, code: false, heading: false }),
      Underline,
      Highlight.configure({ multicolor: true }),
      Superscript,
      Subscript,
      // Custom heading with persistent IDs (H1-H4)
      HeadingWithId.configure({ levels: [1, 2, 3, 4] }),
      TextAlign.configure({ types: ['heading', 'paragraph'] }),
      TaskList,
      TaskItem,
      Image,
      VideoNode,
      AudioNode,
      Link.configure({ openOnClick: false }),
      // Intercept internal #fragment clicks to scroll in-editor
      InternalLinkNavigation,
      MediaDeletionExtension.configure({
        onDelete: (url: string) => {
          if (url.startsWith('https://assets.expotoworld.com/ebooks/huashangdao/')) {
            deleteMediaFromS3(url)
          }
        },
      }),

      // Placeholder.configure({ placeholder: 'Getting started\n\nType to begin  use the toolbar for formatting' }),

      Placeholder.configure({ placeholder: t('placeholder.editor') }),

    ],
    content: '<p>Start writing your book...</p>',
    onUpdate: ({ editor }) => { saveRef.current(editor.getJSON()) },
  })

  useEffect(() => {
    const id = setInterval(() => { if (editor) saveDraft(editor.getJSON()) }, 10 * 60 * 1000)
    return () => clearInterval(id)
  }, [saveDraft, editor])

  // Scroll to hash on initial load (after hydration)
  useEffect(() => {
    if (!editor) return
    const hash = decodeURIComponent(window.location.hash || '')
    if (hash && hash.startsWith('#')) {
      const id = hash.slice(1)
      // try after a short delay to ensure DOM exists
      setTimeout(() => {
        const el = document.getElementById(id)
        if (el) el.scrollIntoView({ behavior: 'smooth', block: 'center' })
      }, 500)
    }
  }, [editor])

  // Fetch latest draft on init (after token + editor are ready) and hydrate editor
  useEffect(() => {
    if (!token || !editor) return
    let cancelled = false
    ;(async () => {
      try {
        const res = await axios.get(`${API_BASE}/api/ebook`, { headers: { Authorization: `Bearer ${token}` } })
        const content = res.data?.content
        if (!cancelled && content && typeof content === 'object' && Object.keys(content || {}).length > 0) {
          // Do not emit update to avoid triggering autosave immediately
          editor.commands.setContent(content, false)
        }
      } catch (e) {
        if ((e as any)?.response?.status === 401) {
          try { localStorage.removeItem('ebook_token') } catch {}
          setToken(null)
        }
      }
    })()
    return () => { cancelled = true }
  }, [token, editor])

  if (authBoot) return <div />
  if (!token) return <Login onToken={setToken} />

  return (
    <ThemeProvider>
      <Shell token={token}
        status={status}
        lastSavedAt={lastSavedAt}
        toolbar={<Toolbar editor={editor} outlineOpen={outlineOpen} onToggleOutline={() => setOutlineOpen(v => !v)} zoomLevel={zoomLevel} onZoomChange={setZoomLevel} onOpenHistory={() => setVersionsOpen(true)} />}
        actionsRight={(
          <>
            <button className="secondary-btn" onClick={() => setVersionsOpen(true)}>
              {t('toolbar.version_history') || 'Version History'}
            </button>
            <button className="primary-btn danger" onClick={() => { setSaveName(''); setSaveOpen(true) }}>
              {t('actions.save_version') || 'Save version'}
            </button>
          </>
        )}

      >
        <div className="editor-surface">
          <div className="editor-viewport" style={{ ['--zoom' as any]: 1 + (zoomLevel - 1) * 0.4 }}>
            <EditorContent editor={editor} />
          </div>
        </div>
        {editor && <OutlineSidebar editor={editor} open={outlineOpen} />}
        {editor && <WordCount editor={editor} />}
      </Shell>
        <Modal open={saveOpen} title={t('actions.save_version') || 'Save version'} onClose={() => setSaveOpen(false)}>
          <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
            <input className="miw-version-input" value={saveName} onChange={e => setSaveName(e.target.value)} placeholder={t('placeholders.version_name') || 'Version name'} />
            <div style={{ display: 'flex', justifyContent: 'flex-end', gap: 8 }}>
              <button className="secondary-btn" onClick={() => setSaveOpen(false)}>{t('common.cancel') || 'Cancel'}</button>
              <button className="primary-btn" onClick={async () => {
                if (!editor) return

                const label = saveName.trim()
                if (!label) {
                  window.dispatchEvent(new CustomEvent('miw:toast' as any, { detail: { message: t('errors.version_name_required') || 'Please enter a version name', type: 'error' } } as any) as any)
                  return
                }
                try {
                  const headers = token ? { Authorization: `Bearer ${token}` } : {}
                  await axios.post(`${API_BASE}/api/ebook/versions`, { label }, { headers })
                  setSaveOpen(false)
                  window.dispatchEvent(new CustomEvent('miw:toast', { detail: { message: t('actions.version_success'), type: 'success' } }))
                } catch {
                  window.dispatchEvent(new CustomEvent('miw:toast', { detail: { message: t('actions.version_fail'), type: 'error' } }))
                }
              }}>{t('common.confirm') || 'Confirm'}</button>
            </div>
          </div>
        </Modal>
        {/* Toast */}
        <div className={`miw-toast ${toastVisible ? 'is-visible' : ''}`}>
          <div className={`miw-toast-card ${toastType}`}>{toastMsg}</div>
        </div>
        <VersionHistorySidebar open={versionsOpen} onClose={() => setVersionsOpen(false)} token={token!} onRestored={(content) => { if (content) editor?.commands.setContent(content, false) }} />
      </ThemeProvider>
    )
  }


