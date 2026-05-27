import axios from 'axios'

// 创建axios实例
const request = axios.create({
  baseURL: 'http://127.0.0.1:3300/api/travel',
  timeout: 60000,
  header: {
    'Content-Type': 'application/json'
  }
})

// 封装拦截器
request.interceptors.request.use(
  config => {
    // 在发送请求之前做些什么
    return config
  },
  error => {
    // 对请求错误做点什么
    return Promise.reject(error)
  }
)

// 封装响应拦截器
request.interceptors.response.use(
  response => {
    // 对响应数据做点什么
    return response.data
  },
  error => {
    // 对响应错误做点什么
    return Promise.reject(error)
  }
)

export function post(url, data) {
  return request.post(url, data)
}

export function get(url, params) {
  return request.get(url, { params })
}

// 处理流式接口
export async function fetchStream(url, data, onChunk, onComplete, onError) {
  // 创建一个请求控制器
  const controller = new AbortController()

  try {
    const response = await fetch(`http://localhost:3300/api/travel/${url}`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json'
      },
      body: JSON.stringify(data),
      signal: controller.signal
    })

    // 获取响应体的可读流读取器
    const reader = response.body.getReader()
    // 将二进制数据解码为字符串
    const decoder = new TextDecoder()
    // 读取流数据
    while (true) {
      const { done, value } = await reader.read()
      if (done) break
      const chunk = decoder.decode(value, { stream: true })
      // 最终拿到有意义的数据
      const lines = chunk.split('\n').filter(line => line.trim())

      for (const line of lines) {
        console.log(line)

        try {
          if (line.startsWith('data: ')) {
            const jsonData = JSON.parse(line.substring(6))
            if (jsonData.type === 'chunk') {
              onChunk(jsonData.content)
            } else if (jsonData.done) {
              onComplete(jsonData.data)
            } else if (jsonData.error) {
              onError(jsonData.error)
            }
          }
        } catch (error) {
          onError('流式数据解析异常')
        }
      }
    }
    return controller.abort()

  } catch (error) {
    onError(error.message)
  }
}