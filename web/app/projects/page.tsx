'use client'

import { useEffect, useState } from 'react'

const backendUrl = process.env.NEXT_PUBLIC_BACKEND_URL || 'http://localhost:8000'

type ProjectSummary = {
  id: number
  name: string
  project_type: string
  domain: string | null
  description: string
  requirement_count: number
  risk_count: number
  knowledge_count: number
}

export default function ProjectsPage() {
  const [projects, setProjects] = useState<ProjectSummary[]>([])
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    setLoading(true)
    fetch(`${backendUrl}/api/v1/projects`)
      .then((res) => res.json())
      .then((data) => setProjects(data))
      .catch((err) => setError(err.message))
      .finally(() => setLoading(false))
  }, [])

  return (
    <div className="panel">
      <div className="hero">
        <h1>项目总览</h1>
        <p>展示当前系统中可用的项目 Demo，以及需求、风险、知识文档的聚合统计。</p>
      </div>

      {error && <div className="notice error">错误：{error}</div>}

      {loading ? (
        <p>加载中…</p>
      ) : (
        <div className="grid">
          {projects.map((project) => (
            <div key={project.id} className="card">
              <h3>{project.name}</h3>
              <p>{project.description}</p>
              <p className="tag">类型：{project.project_type}</p>
              <p className="tag">领域：{project.domain || '未指定'}</p>
              <div className="item-block">
                <p>需求数：{project.requirement_count}</p>
                <p>风险数：{project.risk_count}</p>
                <p>知识数：{project.knowledge_count}</p>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  )
}
