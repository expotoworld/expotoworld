import React, { useEffect, useMemo, useState } from 'react'
import axios from 'axios'
import { useTranslation } from 'react-i18next'
import { ConfirmDialog, Modal } from './Modal'

const API_BASE = (import.meta as any).env?.VITE_API_BASE || 'https://device-api.expotoworld.com'

type VersionItem = {
  id: string
  kind: 'manual' | 'published'
  label?: string | null
  created_at: string
}

type Props = {
  open: boolean
  onClose: () => void
  token: string
  onRestored?: (content: any) => void
}

export default function VersionHistorySidebar({ open, onClose, token, onRestored }: Props) {
  const { t } = useTranslation()
  const headers = useMemo(() => ({ Authorization: `Bearer ${token}` }), [token])
  const [tab, setTab] = useState<'manual'|'published'>('manual')
  const [manual, setManual] = useState<VersionItem[]>([])
  const [published, setPublished] = useState<VersionItem[]>([])
  const [busyId, setBusyId] = useState<string | null>(null)
  const [menuOpen, setMenuOpen] = useState<string | null>(null)
  const [menuPos, setMenuPos] = useState<{ left: number; top: number } | null>(null)
  const [confirm, setConfirm] = useState<{ open: boolean; id?: string; kind?: 'restore'|'delete' }>(() => ({ open: false }))
  const [pubDlg, setPubDlg] = useState<{ open: boolean; id?: string; label: string }>({ open: false, label: '' })
  const [renameDlg, setRenameDlg] = useState<{ open: boolean; id?: string; label: string }>({ open: false, label: '' })

  const load = async (k: 'manual'|'published') => {
    const res = await axios.get(`${API_BASE}/api/ebook/versions?kind=${k}`, { headers })
    const list = (res.data?.items || []) as VersionItem[]
    if (k === 'manual') setManual(list)
    else setPublished(list)
  }

  useEffect(() => { if (open) { load('manual'); load('published') } }, [open])

  const onInspect = (id: string) => {
    window.location.assign(`/ebook-editor/versions/${id}`)
  }

  const openMenu = (e: React.MouseEvent<HTMLButtonElement>, id: string) => {
    const rect = (e.currentTarget as HTMLElement).getBoundingClientRect()
    const menuWidth = 150
    // Default: open facing left of the button
    let left = rect.right - menuWidth
    const top = rect.bottom + 6
    // Bounce to the other side if it would overflow left edge
    if (left < 8) {
      left = Math.min(rect.left, window.innerWidth - menuWidth - 8)
    }
    setMenuPos({ left, top })
    setMenuOpen(prev => prev === id ? null : id)
  }

  const doRestore = async (id: string) => {
    setBusyId(id)
    try {
      await axios.post(`${API_BASE}/api/ebook/versions/${id}/restore`, null, { headers })
      const res = await axios.get(`${API_BASE}/api/ebook`, { headers })
      const content = res.data?.content
      onRestored?.(content)
    } finally { setBusyId(null) }
  }

  const doDelete = async (id: string) => {
    setBusyId(id)
    try {
      await axios.delete(`${API_BASE}/api/ebook/versions/${id}`, { headers })
      await load('manual'); await load('published')
    } finally { setBusyId(null) }
  }

  const doPublish = async (id: string, label: string) => {
    setBusyId(id)
    try {
      await axios.post(`${API_BASE}/api/ebook/versions/${id}/publish`, label ? { label } : {}, { headers })
      await load('published')
    } finally { setBusyId(null) }
  }
  const doRename = async (id: string, label: string) => {
    setBusyId(id)
    try {
      await axios.patch(`${API_BASE}/api/ebook/versions/${id}`, { label }, { headers })
      await load('manual'); await load('published')
      window.dispatchEvent(new CustomEvent('miw:toast' as any, { detail: { message: (t('history.rename.success') as any) || 'Version renamed', type: 'success' } } as any) as any)
      return true
    } catch (err) {
      window.dispatchEvent(new CustomEvent('miw:toast' as any, { detail: { message: (t('history.rename.fail') as any) || 'Failed to rename version', type: 'error' } } as any) as any)
      return false
    } finally { setBusyId(null) }
  }










  const selected = confirm.id ? (manual.find(v => v.id === confirm.id) || published.find(v => v.id === confirm.id)) : undefined
  const selectedLabel = selected?.label || (selected?.kind === 'manual' ? (t('actions.save_version') || 'Save version') : (t('history.tabs.published') || 'Published'))



  if (!open) return null


	
	
	
	
	

  const items = tab === 'manual' ? manual : published

  return (
    <>
      <div className="miw-sidebar-veil" onClick={onClose} />
      <aside className="miw-sidebar" role="complementary" aria-label={t('history.header') || 'Version history'}>
        <div className="miw-sidebar-header">
          <strong>{t('history.header') || 'Version History'}</strong>
          <div className="miw-segmented" role="tablist" aria-label="Version filters">
            <button className={`miw-seg-btn${tab==='manual' ? ' is-active' : ''}`} onClick={() => setTab('manual')} role="tab" aria-selected={tab==='manual'}>{t('history.tabs.manual') || 'Manual'}</button>
            <button className={`miw-seg-btn${tab==='published' ? ' is-active' : ''}`} onClick={() => setTab('published')} role="tab" aria-selected={tab==='published'}>{t('history.tabs.published') || 'Published'}</button>
          </div>
        </div>
        <div className="miw-sidebar-list" onScroll={() => setMenuOpen(null)}>
          {items.length === 0 && (
            <div style={{ padding: 12, color: 'var(--text-muted)' }}>{t('history.empty') || 'No versions yet.'}</div>
          )}
          {items.map(v => (
            <div key={v.id} className="miw-version-row" style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '8px 10px', borderRadius: 8 }}>
              <div className="miw-version-meta">
                <div className="miw-version-title">{v.label || (v.kind === 'manual' ? (t('actions.save_version') || 'Save version') : (t('history.tabs.published') || 'Published'))}</div>
                <div className="miw-version-sub">{new Date(v.created_at).toLocaleString()}</div>
              </div>
              <div className="miw-version-actions" style={{ position: 'relative' }}>
                <button className="toolbar-btn" aria-label="menu" onClick={(e) => openMenu(e, v.id)}>
                  <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor" aria-hidden>
                    <path d="M12 8C13.1046 8 14 7.10457 14 6C14 4.89543 13.1046 4 12 4C10.8954 4 10 4.89543 10 6C10 7.10457 10.8954 8 12 8ZM12 14C13.1046 14 14 13.1046 14 12C14 10.8954 13.1046 10 12 10C10.8954 10 10 10.8954 10 12C10 13.1046 10.8954 14 12 14ZM12 20C13.1046 20 14 19.1046 14 18C14 16.8954 13.1046 16 12 16C10.8954 16 10 16.8954 10 18C10 19.1046 10.8954 20 12 20Z"></path>
                  </svg>
                </button>
                {menuOpen === v.id && (
                  <div
                    className="dropdown-menu"
                    role="menu"
                    style={{ position: 'fixed', left: menuPos?.left ?? 0, top: menuPos?.top ?? 0, minWidth: 150, maxWidth: 220, zIndex: 1000 }}
                    onMouseLeave={() => setMenuOpen(null)}
                  >
                    <div className="menu-item" role="menuitem" onClick={() => { setMenuOpen(null); setRenameDlg({ open: true, id: v.id, label: v.label || '' }) }}>{t('history.actions.rename') || 'Rename'}</div>
                    <div className="menu-item" role="menuitem" onClick={() => { setMenuOpen(null); onInspect(v.id) }}>{t('history.actions.inspect') || 'Inspect'}</div>
                    {v.kind === 'manual' && (
                      <>
                        <div className="menu-item" role="menuitem" onClick={() => { setMenuOpen(null); setConfirm({ open: true, id: v.id, kind: 'restore' }) }}>{t('history.actions.restore') || 'Restore'}</div>
                        <div className="menu-item" role="menuitem" onClick={() => { setMenuOpen(null); setPubDlg({ open: true, id: v.id, label: '' }) }}>{t('history.actions.publish') || 'Publish'}</div>
                      </>
                    )}
                    <div className="menu-item" role="menuitem" onClick={() => { setMenuOpen(null); setConfirm({ open: true, id: v.id, kind: 'delete' }) }} style={{ color: 'var(--color-danger, #d92525)' }}>{t('history.actions.delete') || 'Delete'}</div>
                  </div>
                )}
              </div>
            </div>
          ))}
        </div>
      </aside>

      {/* Restore/Delete confirmations */}
      <ConfirmDialog
        open={confirm.open}
        title={confirm.kind === 'delete' ? (t('history.actions.delete') || 'Delete') : (t('history.actions.restore') || 'Restore')}
        message={confirm.kind === 'delete' ? ((t('history.confirm.delete_label', { label: selectedLabel }) as any) || `Are you sure you want to delete "${selectedLabel}"?`) : (t('history.confirm.restore') || 'Restore this version? This will replace the current draft.')}
        confirmText={t('common.confirm') || 'Confirm'}
        cancelText={t('common.cancel') || 'Cancel'}
        onCancel={() => setConfirm({ open: false })}
        onConfirm={async () => {
          const id = confirm.id!
          const kind = confirm.kind!
          setConfirm({ open: false })
          if (kind === 'delete') await doDelete(id)
          else await doRestore(id)
        }}
      />
      {/* Rename dialog */}
      <Modal open={renameDlg.open} title={t('history.rename.title') || 'Rename version'} onClose={() => setRenameDlg({ open: false, label: '' })}>
        <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
          <input className="miw-version-input" value={renameDlg.label} onChange={e => setRenameDlg(s => ({ ...s, label: e.target.value }))} placeholder={t('placeholders.version_name') || 'Version name'} />
          <div style={{ display: 'flex', justifyContent: 'flex-end', gap: 8 }}>
            <button className="secondary-btn" onClick={() => setRenameDlg({ open: false, label: '' })}>{t('common.cancel') || 'Cancel'}</button>
            <button className="primary-btn" onClick={async () => {
              const id = renameDlg.id!
              const label = renameDlg.label.trim()
              if (!label) {
                window.dispatchEvent(new CustomEvent('miw:toast' as any, { detail: { message: t('errors.version_name_required') || 'Please enter a version name', type: 'error' } } as any) as any)
                return
              }
              const ok = await doRename(id, label)
              if (ok) setRenameDlg({ open: false, label: '' })
            }}>{t('common.save') || 'Save'}</button>
          </div>
        </div>
      </Modal>


      {/* Publish dialog */}
      <Modal open={pubDlg.open} title={t('history.publish.title') || 'Publish version'} onClose={() => setPubDlg({ open: false, label: '' })}>
        <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
          <input className="miw-version-input" value={pubDlg.label} onChange={e => setPubDlg(s => ({ ...s, label: e.target.value }))} placeholder={t('placeholders.version_name') || 'Version name'} />
          <div style={{ display: 'flex', justifyContent: 'flex-end', gap: 8 }}>
            <button className="secondary-btn" onClick={() => setPubDlg({ open: false, label: '' })}>{t('common.cancel') || 'Cancel'}</button>
            <button className="primary-btn" onClick={async () => {
              const id = pubDlg.id!
              const label = pubDlg.label.trim()
              if (!label) {
                window.dispatchEvent(new CustomEvent('miw:toast' as any, { detail: { message: t('errors.version_name_required') || 'Please enter a version name', type: 'error' } } as any) as any)
                return
              }
              setPubDlg({ open: false, label: '' })
              await doPublish(id, label)
            }}>{t('common.confirm') || 'Confirm'}</button>
          </div>
        </div>
      </Modal>
    </>
  )
}

