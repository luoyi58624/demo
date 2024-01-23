import { createRouter, createWebHashHistory } from 'vue-router'

const router = createRouter({
	// 4. 内部提供了 history 模式的实现。为了简单起见，我们在这里使用 hash 模式。
	history: createWebHashHistory(),
	routes: [
		{
			path: '/:pathMatch(.*)*',
			component: () => import('@/pages/common/transfer_router.vue')
		},
		{
			path: '/404',
			name: 'NotFound',
			component: () => import('@/pages/common/not_found.vue')
		},
		{
			path: '/',
			name: 'Home',
			component: () => import('@/pages/home.vue')
		},
		{
			path: '/test',
			name: 'Test',
			component: () => import('@/pages/test.vue')
		}
	]
})

router.beforeEach(() => {
	return true
})

router.afterEach(() => {})

export default router
