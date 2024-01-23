import {
	defineConfig,
	presetAttributify,
	presetIcons,
	presetTypography,
	presetUno,
	transformerDirectives,
	transformerVariantGroup
} from 'unocss'

import { colors } from 'unocss/preset-mini'

const colorType = ['primary', 'success', 'warning', 'error', 'info']

export default defineConfig({
	presets: [
		presetUno({
			dark: 'media'
		}),
		presetIcons({
			prefix: 'i-',
			scale: 1.5
		}),
		presetAttributify(),
		presetTypography()
	],
	transformers: [transformerDirectives(), transformerVariantGroup()],
	theme: {
		breakpoints: {
			xs: '0px',
			sm: '640px',
			md: '768px',
			lg: '1024px',
			xl: '1280px',
			'2xl': '1440px'
		},
		colors: {
			primary: colors.sky,
			success: colors.teal,
			warning: colors.amber,
			error: colors.red,
			info: colors.slate
		}
	},
	shortcuts: [
		{
			'flex-center': 'flex justify-center items-center',
			'inline-flex-center': 'inline-flex justify-center items-center'
		},
		[
			/^btn-(.*)$/,
			([, c]) =>
				`m-1 px-4 py-2 rounded-1 select-none text-white m-transition bg-${c}-5 active:bg-${c}-5 hover:(ring-2 ring-offset-2 ring-${c}-5)`
		]
	],
	rules: [['m-transition', { transition: 'all ease-out 0.3s' }]],
	safelist: [
		// ...'prose prose-sm m-auto text-left'.split(' '),
		// ...colorType.map(item => {
		// 	return `bg-${item}`
		// }),
		// ...colorType.map(item => {
		// 	return `text-${item}`
		// })
	]
})
