import { defineConfig, loadEnv } from 'vite'
import * as path from 'path'
import vue from '@vitejs/plugin-vue'
import UnoCSS from 'unocss/vite'
import AutoImport from 'unplugin-auto-import/vite'
import Components from 'unplugin-vue-components/vite'

export default defineConfig(({ mode }) => {
	const env = loadEnv(mode, process.cwd(), '')
	return {
		base: env.BUILD_BASE_URL,
		resolve: {
			alias: {
				'@': path.resolve(__dirname, 'src')
			}
		},
		plugins: [
			vue(),
			UnoCSS(),
			AutoImport({
				imports: ['vue', 'vue-router', 'pinia', '@vueuse/core'],
				dirs: ['./src/stores', './src/utils']
			}),
			Components({
				dirs: ['src/components'], // 搜索目录
				extensions: ['vue', 'tsx'], // 组件有效扩展名
				directoryAsNamespace: true, // 允许父文件夹作为组件名称前缀
				deep: true, // 搜索子目录
				dts: true // 生成d.ts描述文件
			})
		],
		server: {
			port: 5173
		},
		build: {
			cssCodeSplit: false, // css代码分割，true启用、false禁止
			chunkSizeWarningLimit: 2000, // 文件大小超出警告，单位kb
			terserOptions: {
				compress: {
					//生产环境时移除console和debug
					drop_console: true,
					drop_debugger: true
				}
			},
			rollupOptions: {
				output: {
					entryFileNames: `js/App.${new Date().getTime()}.js`,
					chunkFileNames: `js/[name].${new Date().getTime()}.js`,
					assetFileNames: `assets/[name].${new Date().getTime()}.[ext]`,
					compact: true,
					manualChunks: {
						vue: ['vue']
					}
				}
			}
		}
	}
})
