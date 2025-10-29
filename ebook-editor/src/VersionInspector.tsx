import React, { useEffect } from 'react'
import { useParams, useNavigate } from 'react-router-dom'
import axios from 'axios'
import { useEditor, EditorContent } from '@tiptap/react'
import StarterKit from '@tiptap/starter-kit'
import Underline from '@tiptap/extension-underline'
import Highlight from '@tiptap/extension-highlight'
import Superscript from '@tiptap/extension-superscript'
import Subscript from '@tiptap/extension-subscript'
import TextAlign from '@tiptap/extension-text-align'
import Image from '@tiptap/extension-image'
import Link from '@tiptap/extension-link'
import TaskList from '@tiptap/extension-task-list'
import TaskItem from '@tiptap/extension-task-item'
import { HeadingWithId } from './extensions/HeadingWithId'
import { InternalLinkNavigation } from './extensions/InternalLinkNavigation'
import { VideoNode } from './nodes/VideoNode'
import { AudioNode } from './nodes/AudioNode'
import { useTranslation } from 'react-i18next'

const API_BASE = (import.meta as any).env?.VITE_API_BASE || 'https://device-api.expotoworld.com'

export default function VersionInspector() {
  const { id } = useParams<{ id: string }>()
  const nav = useNavigate()

  const editor = useEditor({
    editable: false,
    extensions: [
      StarterKit.configure({ codeBlock: false, code: false, heading: false }),
      Underline,
      Highlight.configure({ multicolor: true }),
      Superscript,
      Subscript,
      HeadingWithId.configure({ levels: [1, 2, 3, 4] }),
      TextAlign.configure({ types: ['heading', 'paragraph'] }),
      TaskList,
      TaskItem,
      Image,
      VideoNode,
      AudioNode,
      Link.configure({ openOnClick: true }),
      InternalLinkNavigation,
    ],
    content: '<p />'
  })

  useEffect(() => {
    let cancelled = false
    ;(async () => {
      try {
        const stored = (() => { try { return JSON.parse(localStorage.getItem('ebook_token') || 'null') } catch { return null } })()
        const tok = stored?.token as string | undefined
        if (!tok) { nav('/'); return }
        const res = await axios.get(`${API_BASE}/api/ebook/versions/${id}/content`, { headers: { Authorization: `Bearer ${tok}` } })
        const content = res.data?.content
        if (!cancelled && editor && content) editor.commands.setContent(content, false)
      } catch (e) {
        console.error('Failed to load version content', e)
      }
    })()
    return () => { cancelled = true }
  }, [id, editor])

  const { t } = useTranslation()
  return (
    <div className="editor-app">
      <div className="editor-header">
        <div className="editor-topbar">
          <div className="topbar-left">
            <button className="toolbar-btn" onClick={() => nav(-1)} aria-label="Back">
              <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor" aria-hidden>
                <path d="M22.0003 13.0001L22.0004 11.0002L5.82845 11.0002L9.77817 7.05044L8.36396 5.63623L2 12.0002L8.36396 18.3642L9.77817 16.9499L5.8284 13.0002L22.0003 13.0001Z"></path>
              </svg>
            </button>
          </div>
          <div className="topbar-right">
            <span className="status-badge">{t('version.readOnly')}</span>
          </div>
        </div>
      </div>
      <div className="editor-container">
        <div className="editor-surface">
          <div className="editor-viewport">
            <EditorContent editor={editor} />
          </div>
        </div>
      </div>
    </div>
  )
}
