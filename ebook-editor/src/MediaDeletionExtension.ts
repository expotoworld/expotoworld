import { Extension } from '@tiptap/core'
import { Plugin, PluginKey } from '@tiptap/pm/state'
import axios from 'axios'

const API_BASE = (import.meta as any).env?.VITE_API_BASE || 'https://device-api.expotoworld.com'

export interface MediaDeletionOptions {
  onDelete?: (url: string) => void
}

export const MediaDeletionExtension = Extension.create<MediaDeletionOptions>({
  name: 'mediaDeletion',

  addOptions() {
    return {
      onDelete: undefined,
    }
  },

  addProseMirrorPlugins() {
    const { onDelete } = this.options

    return [
      new Plugin({
        key: new PluginKey('mediaDeletion'),
        appendTransaction: (transactions, oldState, newState) => {
          const deletedSrcs: string[] = []

          transactions.forEach((tr) => {
            if (!tr.docChanged) return

            const oldSrcs = new Set<string>()
            oldState.doc.descendants((node) => {
              if ((node.type.name === 'image' || node.type.name === 'video' || node.type.name === 'audio') && node.attrs.src) {
                oldSrcs.add(node.attrs.src)
              }
            })

            const newSrcs = new Set<string>()
            newState.doc.descendants((node) => {
              if ((node.type.name === 'image' || node.type.name === 'video' || node.type.name === 'audio') && node.attrs.src) {
                newSrcs.add(node.attrs.src)
              }
            })

            oldSrcs.forEach((src) => { if (!newSrcs.has(src)) deletedSrcs.push(src) })
          })

          if (deletedSrcs.length > 0 && onDelete) {
            deletedSrcs.forEach((u) => onDelete(u))
          }
          return null
        },
      }),
    ]
  },
})

export async function deleteMediaFromS3(mediaUrl: string): Promise<void> {
  try {
    const token = (() => {
      try { return JSON.parse(localStorage.getItem('ebook_token') || 'null')?.token || null } catch { return null }
    })()
    if (!token) return

    await axios.delete(`${API_BASE}/api/ebook/delete-media`, {
      data: { media_url: mediaUrl },
      headers: { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json', Accept: 'application/json' },
    })
  } catch (e) {
    console.error('Failed to schedule media deletion', e)
  }
}

