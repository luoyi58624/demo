import axios from 'axios'

const axiosInstance = axios.create({
	baseURL: import.meta.env.DEV ? '/api' : 'http://localhost:8081',
	timeout: 5000
})

// 请求拦截
axiosInstance.interceptors.request.use(
	request => {
		// if (!isEmpty(localStorage.getItem(StorageKey.token))) {
		// 	request.headers.token = localStorage.getItem(StorageKey.token);
		// }
		return request
	},
	error => {
		return error
	}
)

// 响应拦截
axiosInstance.interceptors.response.use(
	response => {
		// 如果为200直接返回服务器对象
		if (response.data.code == 200) {
			return response.data
		}
		if (response.data.code == 401) {
			// router.replace('/login').then(() => {
			// 	const userStore = useUserStore();
			// 	userStore.logoutHandler();
			// 	message(response.data.msg, 'error');
			// });
			return
		}
		// message(response.data.msg, 'error');
		return Promise.reject(response.data)
	},
	error => {
		let text
		if (error.message.indexOf('Network Error') !== -1) {
			text = '无法连接服务器'
		} else if (error.message.indexOf('timeout') !== -1) {
			text = '服务器请求超时'
		} else if (error.response.status === 404) {
			text = '请求接口不存在'
		} else if (error.response.status === 500) {
			text = '服务内部错误'
		}
		// message(text, 'error');
		console.log(text)
		return Promise.reject(error)
	}
)
export { axios, axiosInstance }
