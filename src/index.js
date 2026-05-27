import express from 'express'
import travelRouter from './routes/travel.js'
import 'dotenv/config'
import cors from 'cors'

const app = express()
const port = process.env.PORT

// 跨域问题
app.use(cors())

app.use(express.json())
app.use(express.urlencoded({ extended: true }))

// 创建一个心跳接口
app.post('/api/heartbeat', (req, res) => {
  console.log(req.query)
  console.log(req.body)
  res.json({
    message: '服务正常运行',
    timestamp: new Date().toISOString()
  })
})

// 创建一个中间件
app.use('/api/travel', travelRouter)

app.listen(port, () => {
  console.log(`服务地址：http://localhost:${port}`)
})
