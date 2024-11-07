import { createStore } from 'vuex'
import api from '@/services/api'

export default createStore({
  state: {
    user: null,
    books: []
  },
  mutations: {
    setUser(state, user) {
      state.user = user
    },
    setBooks(state, books) {
      state.books = books
    }
  },
  actions: {
    async fetchBooks({ commit }) {
      try {
        const { books } = await api.get('/api/books')
        commit('setBooks', books || [])
      } catch (error) {
        console.error('Error fetching books:', error)
        commit('setBooks', [])
        throw error // 向上传递错误以便UI处理
      }
    }
  }
})
