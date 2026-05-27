<template>
  <div class="page-container chat-page">
    <div class="page-header">
      <van-nav-bar title="AI 旅游助手" fixed left-arrow left-text="返回" @click-left="onBack" />
    </div>
    <div class="chat-container" ref="chatContainer">
      <div v-if="messages.length === 0" class="chat-empty">
        <van-empty description="开始和 AI 助手对话吧！" />
        <div class="quick-questions">
          <div class="quick-title">常见问题</div>
          <van-tag v-for="item in quickQuestions" :key="item" class="quick-tag" size="large" mark
            @click="handleClickTag(item)">{{ item }}</van-tag>
        </div>
      </div>
      <div v-else class="message-list">
        <ChatBubble v-for="item in messages" :key="item.id" :message="item" />
        <div v-if="isStreaming" class="streaming-indicator">
          <van-loading type="spiner" size="20px" />
          <span>AI 正在思考中...</span>
        </div>
      </div>
    </div>
    <div class="chat-input-area">
      <van-field v-model="inputMessage" placeholder="输入您的问题..." :disabled="isStreaming" @keyup.enter="sendMessage">
        <template #button>
          <van-button type="primary" size="small" :disabled="!inputMessage.trim()" @click="sendMessage">发送</van-button>
        </template>
      </van-field>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted, nextTick } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { fetchStream } from '@/utils/request'
import ChatBubble from '@/components/ChatBubble.vue'

const chatContainer = ref(null)

// 置底的方法
const scrollToBottom = () => {
  if (chatContainer.value) {
    chatContainer.value.scrollTop = chatContainer.value.scrollHeight
  }
}

const router = useRouter()

// 常见问题
const quickQuestions = ref([
  '北京有哪些必去的景点？',
  '上海美食推荐',
  '成都三日游攻略',
  '如何选择旅行保险？'
])

// 会话数据
const messages = ref([])

// 输入框数据
const inputMessage = ref('')

const onBack = () => {
  router.back()
}

const handleClickTag = () => {

}

const sendMessage = () => {
  const msg = inputMessage.value.trim()
  if (!msg || isStreaming.value) return

  addUserMessage(msg)
  inputMessage.value = ''
  nextTick(scrollToBottom) // 添加滚动到底部的调用

  // 进行流式请求
  fetchAIResponse(msg)
}

const fetchAIResponse = (userMsg) => {
  isStreaming.value = true
  messages.value.push({
    id: Date.now() + 1,
    role: 'ai',
    content: '',
    timestamp: new Date().toISOString()
  })

  let fullResponse = ''

  fetchStream('chat', { message: userMsg }, (chunk) => {
    fullResponse += chunk
    const lastMsg = messages.value[messages.value.length - 1]
    if (lastMsg && lastMsg.role === 'ai') {
      lastMsg.content = fullResponse
    }
    scrollToBottom()
  }, () => {
    // AI 返回完成
    isStreaming.value = false
    nextTick(scrollToBottom)
  }, (error) => {
    const lastMsg = messages.value[messages.value.length - 1]
    if (lastMsg && lastMsg.role === 'ai') {
      lastMsg.content = `抱歉，AI 发生错误：${error}`
    }
    isStreaming.value = false
    showToast('ai回复失败')
    nextTick(scrollToBottom)
  })
}

// AI 处理状态
const isStreaming = ref(false)

// 用户发送消息
const addUserMessage = (message) => {
  messages.value.push({
    id: Date.now(),
    role: 'user',
    content: message,
    timestamp: new Date().toISOString()
  })
}

const route = useRoute()

onMounted(() => {
  if (route.query.scene === 'detail' && route.query.city) {
    inputMessage.value = `我想了解一下${route.query.city}的旅游景点`
  }
})

</script>

<style scoped>
.page-header {
  height: 46px;
}

.chat-page {
  display: flex;
  flex-direction: column;
  height: 100vh;
  padding-bottom: 0 !important;
}

.chat-container {
  flex: 1;
  overflow-y: auto;
  padding: 16px;
  padding-bottom: 130px;
  /* 增加底部内边距，确保内容不被输入框遮挡 */
}

.chat-empty {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  height: 100%;
}

.quick-questions {
  margin-top: 32px;
  text-align: center;
}

.quick-title {
  font-size: 14px;
  color: #999;
  margin-bottom: 16px;
}

.quick-tag {
  margin: 8px;
  cursor: pointer;
}

.message-list {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.streaming-indicator {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 8px 16px;
  color: #999;
  font-size: 14px;
}

.chat-input-area {
  position: fixed;
  bottom: 50px;
  left: 0;
  right: 0;
  background: #fff;
  padding: 8px 16px;
  box-shadow: 0 -2px 8px rgba(0, 0, 0, 0.05);
  max-width: 750px;
  margin: 0 auto;
}

.chat-input-area :deep(.van-field) {
  background: #f7f8fa;
  border-radius: 20px;
  padding: 8px 16px;
}
</style>