import { Node, mergeAttributes } from '@tiptap/core'

export interface AudioOptions {
  HTMLAttributes: Record<string, any>
}

declare module '@tiptap/core' {
  interface Commands<ReturnType> {
    audio: {
      setAudio: (options: { src: string }) => ReturnType
    }
  }
}

export const AudioNode = Node.create<AudioOptions>({
  name: 'audio',
  group: 'block',
  atom: true,
  draggable: true,
  selectable: true,

  addOptions() {
    return { HTMLAttributes: { controls: true, style: 'width:100%;' } }
  },

  addAttributes() { return { src: { default: null } } },

  parseHTML() { return [{ tag: 'audio' }] },

  renderHTML({ HTMLAttributes }) { return ['audio', mergeAttributes(this.options.HTMLAttributes, HTMLAttributes)] },

  addCommands() {
    return {
      setAudio:
        ({ src }) => ({ commands }) =>
          commands.insertContent({ type: this.name, attrs: { src } }),
    }
  },
})

