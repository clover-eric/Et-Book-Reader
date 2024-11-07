<template>
  <div class="home">
    <h1>Welcome to Et-Book</h1>
    
    <!-- 操作栏 -->
    <div class="action-bar">
      <el-button 
        type="primary" 
        @click="handleFetchBooks" 
        :loading="loading"
        :disabled="loading"
      >
        {{ loading ? 'Loading...' : 'Refresh Books' }}
      </el-button>
    </div>
    
    <!-- 错误提示 -->
    <el-alert
      v-if="error"
      :title="getErrorMessage(error)"
      type="error"
      show-icon
      @close="error = ''"
      class="error-alert"
    />

    <!-- 加载状态 -->
    <div v-if="loading" class="books-container">
      <el-skeleton 
        v-for="i in 6" 
        :key="i"
        animated
        :loading="true"
      >
        <template #template>
          <div class="book-skeleton">
            <el-skeleton-item variant="h3" style="width: 50%" />
            <el-skeleton-item variant="text" style="margin-top: 16px" />
            <el-skeleton-item variant="text" style="width: 80%" />
          </div>
        </template>
      </el-skeleton>
    </div>

    <!-- 空状态 -->
    <el-empty
      v-else-if="!books.length"
      description="No books available"
      :image-size="200"
    >
      <template #description>
        <p>No books available. Try refreshing or come back later.</p>
      </template>
    </el-empty>

    <!-- 图书列表 -->
    <div v-else class="books-container">
      <book-card
        v-for="book in books"
        :key="book.id"
        :book="book"
        @click="handleBookClick(book)"
      />
    </div>
  </div>
</template>

<script>
import { mapState, mapActions } from 'vuex'
import BookCard from '@/components/BookCard.vue'

export default {
  name: 'Home',
  components: {
    BookCard
  },
  data() {
    return {
      loading: false,
      error: ''
    }
  },
  computed: {
    ...mapState(['books'])
  },
  methods: {
    ...mapActions(['fetchBooks']),
    
    // 错误消息处理
    getErrorMessage(error) {
      if (error.response) {
        const { code } = error.response.data
        switch (code) {
          case 'FETCH_ERROR':
            return 'Unable to load books. Please try again.'
          case 'AUTH_ERROR':
            return 'Authentication error. Please login again.'
          default:
            return 'An unexpected error occurred.'
        }
      }
      return 'Network error. Please check your connection.'
    },
    
    // 加载图书
    async handleFetchBooks() {
      if (this.loading) return
      
      this.loading = true
      this.error = ''
      
      try {
        await this.fetchBooks()
      } catch (error) {
        this.error = error
      } finally {
        this.loading = false
      }
    },
    
    // 图书点击处理
    handleBookClick(book) {
      // 预留图书详情功能
      console.log('Book clicked:', book)
    }
  },
  // 组件挂载时自动加载
  async mounted() {
    if (!this.books.length) {
      await this.handleFetchBooks()
    }
  }
}
</script>

<style scoped>
.home {
  padding: 20px;
  max-width: 1200px;
  margin: 0 auto;
}

.action-bar {
  margin: 20px 0;
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.error-alert {
  margin: 20px 0;
}

.books-container {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
  gap: 20px;
  margin-top: 20px;
}

.book-skeleton {
  padding: 20px;
  border: 1px solid #eee;
  border-radius: 4px;
  height: 200px;
}

@media (max-width: 768px) {
  .books-container {
    grid-template-columns: 1fr;
  }
  
  .home {
    padding: 10px;
  }
}
</style>
