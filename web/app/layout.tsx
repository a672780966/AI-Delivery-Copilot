import './globals.css'
import type { Metadata } from 'next'
import type { ReactNode } from 'react'
import Link from 'next/link'

export const metadata: Metadata = {
  title: 'AI Delivery Copilot',
  description: 'ERP/CRM/CDP/OA 项目交付 AI 中控系统',
}

export default function RootLayout({ children }: { children: ReactNode }) {
  return (
    <html lang="zh-CN">
      <body>
        <div className="app-shell">
          <header className="site-header">
            <div>
              <p className="brand">AI Delivery Copilot</p>
              <p className="tagline">ERP/CRM/CDP/OA 项目交付中控平台</p>
            </div>
            <nav className="site-nav">
              <Link href="/">首页</Link>
              <Link href="/projects">项目总览</Link>
              <Link href="/requirements">需求池</Link>
              <Link href="/risk">风险雷达</Link>
            </nav>
          </header>
          <main className="app-content">{children}</main>
        </div>
      </body>
    </html>
  )
}
