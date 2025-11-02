import React, { useMemo, useState } from 'react'
import type { Editor } from '@tiptap/react'
import type { DictTerm } from '../extensions/DictionaryTerm'
import { linkAllTerms, removeAllDictionaryMarksById } from '../extensions/DictionaryTerm'
import { Modal, ConfirmDialog } from './Modal'
import { upsertDictionaryMetaInEditor } from '../extensions/DictionaryMeta'
import { useTranslation } from 'react-i18next'

function PlusIcon() {
  return (
    <svg viewBox="0 0 24 24" width="18" height="18" fill="currentColor" aria-hidden>
      <path d="M11 5h2v6h6v2h-6v6h-2v-6H5v-2h6z"/>
    </svg>
  )
}
function EditIcon() {
  return (
    <svg viewBox="0 0 24 24" width="18" height="18" fill="currentColor" aria-hidden>
      <path d="M3 17.25V21h3.75L17.81 9.94l-3.75-3.75L3 17.25zM20.71 7.04a1.003 1.003 0 000-1.42l-2.34-2.34a1.003 1.003 0 00-1.42 0l-1.83 1.83 3.75 3.75 1.84-1.82z"/>
    </svg>
  )
}
function TrashIcon() {
  return (
    <svg viewBox="0 0 24 24" width="18" height="18" fill="currentColor" aria-hidden>
      <path d="M6 19a2 2 0 002 2h8a2 2 0 002-2V7H6v12zM19 4h-3.5l-1-1h-5l-1 1H5v2h14V4z"/>
    </svg>
  )
}

export default function DictionarySidebar({ open, onClose, editor, terms, setTerms }: {
  open: boolean
  onClose: () => void
  editor: Editor
  terms: DictTerm[]
  setTerms: (next: DictTerm[]) => void
}) {
  const { t } = useTranslation()
  const [dialogOpen, setDialogOpen] = useState(false)
  const [editing, setEditing] = useState<DictTerm | null>(null)
  const [draftDef, setDraftDef] = useState('')
  const [confirmDel, setConfirmDel] = useState<DictTerm | null>(null)

  const canAddFromSelection = useMemo(() => {
    if (!editor) return false
    const sel = editor.state.selection
    if (sel.empty) return false
    if (editor.isActive('link') || editor.isActive('dictionaryTerm')) return false
    const text = editor.state.doc.textBetween(sel.from, sel.to, ' ')
    return !!text.trim()
  }, [editor?.state?.selection])

  function onAddClick() {
    const sel = editor.state.selection
    const text = editor.state.doc.textBetween(sel.from, sel.to, ' ')
    setEditing({ id: '', term: text.trim(), definition: '' })
    setDraftDef('')
    setDialogOpen(true)
  }

  function saveEditing() {
    if (!editing || !editing.term.trim()) { setDialogOpen(false); return }
    const exists = terms.find(t => t.term.toLowerCase() === editing.term.toLowerCase())
    const id = exists?.id || ('d_' + Math.random().toString(36).slice(2))
    const next = exists
      ? terms.map(t => t.id === exists.id ? { ...t, definition: draftDef } : t)
      : [...terms, { id, term: editing.term.trim(), definition: draftDef }]
    setTerms(next)
    upsertDictionaryMetaInEditor(editor, next)
    linkAllTerms(editor, next)
    setDialogOpen(false)
    setEditing(null)
  }

  function onEdit(item: DictTerm) {
    setEditing(item)
    setDraftDef(item.definition || '')
    setDialogOpen(true)
  }

  function onDelete(item: DictTerm) {
    setConfirmDel(item)
  }
  function confirmDelete() {
    if (!confirmDel) return
    const next = terms.filter(t => t.id !== confirmDel.id)
    setTerms(next)
    upsertDictionaryMetaInEditor(editor, next)
    removeAllDictionaryMarksById(editor, confirmDel.id)
    setConfirmDel(null)
  }


  if (!open) return null

  return (
    <>
      <div className="miw-sidebar-veil" onClick={onClose} />
      <aside className="miw-sidebar" role="complementary" aria-label={t('dictionary.sidebar_aria') || 'Dictionary sidebar'}>
        <div className="miw-sidebar-header">
          <div style={{ fontWeight: 700 }}>{t('dictionary.sidebar_title') || 'Dictionary'}</div>
          <button className="toolbar-btn" onClick={onAddClick} disabled={!canAddFromSelection} data-tooltip={canAddFromSelection ? (t('dictionary.add_selected') || 'Add selected text') : (t('dictionary.select_to_add') || 'Select text to add')}>
            <PlusIcon /><span>{t('dictionary.add') || 'Add'}</span>
          </button>
        </div>
        <div className="miw-sidebar-list">
          {terms.length === 0 && (
            <div style={{ padding: '8px 12px', color: 'var(--color-muted)' }}>{t('dictionary.empty') || 'No terms yet. Select text and click Add.'}</div>
          )}
          {terms.map(ti => (
            <div key={ti.id} id={`dict-row-${ti.id}`} className="miw-media-row">
              <div className="miw-media-name" title={ti.term} style={{ flex: 1, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{ti.term}</div>
              <div id={`dict-row-btns-${ti.id}`} style={{ display: 'inline-flex', gap: 8 }}>
                <button className="link-action" onClick={() => onEdit(ti)} aria-label={t('dictionary.actions.edit') || 'Edit'}><EditIcon /></button>
                <button className="link-action" onClick={() => onDelete(ti)} aria-label={t('dictionary.actions.delete') || 'Delete'}><TrashIcon /></button>
              </div>
            </div>
          ))}
        </div>
      </aside>

      <Modal open={dialogOpen} title={editing?.id ? (t('dictionary.modal.edit_title') || 'Edit term') : (t('dictionary.modal.add_title') || 'Add term')} onClose={() => setDialogOpen(false)} width={520}>
        <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
          <label style={{ fontSize: 13, color: 'var(--color-muted)' }}>{t('dictionary.field.term') || 'Term'}</label>
          <input className="miw-version-input" value={editing?.term || ''} disabled />
          <label style={{ fontSize: 13, color: 'var(--color-muted)' }}>{t('dictionary.field.definition') || 'Definition'}</label>
          <textarea className="miw-version-input" style={{ minHeight: 140, maxHeight: 260, resize: 'none' }} value={draftDef} onChange={e => setDraftDef(e.target.value)} />
          <div style={{ display: 'flex', justifyContent: 'flex-end', gap: 8, marginTop: 8 }}>
            <button className="secondary-btn" onClick={() => setDialogOpen(false)}>{t('common.cancel') || 'Cancel'}</button>
            <button className="primary-btn" onClick={saveEditing}>{t('common.save') || 'Save'}</button>
          </div>
        </div>
      </Modal>

      <ConfirmDialog open={!!confirmDel} title={t('dictionary.confirm.delete_title') || 'Delete term'} message={(t('dictionary.confirm.delete_message', { term: confirmDel?.term || '' }) || `Remove "${confirmDel?.term}" from dictionary and unlink all occurrences?`) as string} onCancel={() => setConfirmDel(null)} onConfirm={confirmDelete} />
    </>
  )
}

