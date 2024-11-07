import { createApp } from 'vue'
import App from './App.vue'
import router from './router'
import store from './store'
import ElementPlus from 'element-plus'
import 'element-plus/dist/index.css'

const app = createApp(App)

// 全局错误处理
app.config.errorHandler = (err, vm, info) => {
    console.error('Global error:', err);
    console.error('Error info:', info);
    // 可以在这里添加错误上报逻辑
};

app.use(router)
app.use(store)
app.use(ElementPlus)

app.mount('#app')
