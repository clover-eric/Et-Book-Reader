<template>
  <el-card class="book-card" shadow="hover">
    <template #header>
      <div class="book-header">
        {{ book.title }}
      </div>
    </template>
    <div class="book-content">
      <p v-if="book.author">Author: {{ book.author }}</p>
      <p v-if="book.description">{{ book.description }}</p>
    </div>
  </el-card>
</template>

<script>
export default {
  name: 'BookCard',
  props: {
    book: {
      type: Object,
      required: true
    }
  }
}
</script>

<style scoped>
.book-card {
  height: 100%;
}

.book-header {
  font-weight: bold;
  font-size: 1.1em;
}

.book-content {
  color: #666;
}
</style> 