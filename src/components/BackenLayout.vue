<template>
  <div class="backend-layout">
    <el-container class="main-container">
      <Sidebar />
      <el-container>
        <el-header>
          <Navbar />
        </el-header>
        <el-main class="main-content">
          <router-view class="content-container" />
        </el-main>
      </el-container>
    </el-container>
  </div>
</template>

<script setup>
import Sidebar from './Sidebar.vue'
import Navbar from './Navbar.vue'
</script>

<style lang="scss" scoped>
.backend-layout {
  min-height: 100vh;
  display: flex;
  flex-direction: column;

  .el-header {
    height: 74px !important;
  }

  .main-container {
    flex: 1;
    display: flex;

    .main-content {
      flex: 1;
      overflow: auto;
    }

    .content-container {
      padding: 20px;
      background-color: #fff;
      min-height: calc(100% - 74px);
    }
  }
}
</style>
