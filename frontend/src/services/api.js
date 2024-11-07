import axios from 'axios'

const api = axios.create({
  baseURL: import.meta.env.VITE_API_URL,
  timeout: 5000,
  headers: {
    'Content-Type': 'application/json'
  }
})

// 请求拦截器
api.interceptors.request.use(
  config => {
    const token = localStorage.getItem('token')
    if (token) {
      config.headers.Authorization = `Bearer ${token}`
    }
    return config
  },
  error => {
    return Promise.reject(error)
  }
)

// 响应拦截器
api.interceptors.response.use(
  response => response.data,
  error => {
    if (error.response) {
      // 处理后端返回的错误
      const { code, message } = error.response.data
      console.error(`API Error: ${code}`, message)
    } else {
      // 处理网络错误
      console.error('Network Error:', error.message)
    }
    return Promise.reject(error)
  }
)

export default api 