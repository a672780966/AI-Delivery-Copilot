'use client'

import { useEffect, useState } from 'react'

const backendUrl = process.env.NEXT_PUBLIC_BACKEND_URL || 'http://localhost:8000'

type RequirementItem = {
  scope: string
  description: string
  priority: string
  acceptance_criteria: string[]
}

type RequirementList = {
  project_id: number
  project_name: string
  requirements: RequirementItem[]
}

export default function RequirementsPage() {
  const [items, setItems] = useState<RequirementList[]>([])
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    setLoading(true)
    fetch(`${backendUrl}/api/v1/requirements`)
      .then((res) => res.json())
      .then((data) => setItems(data))
      .catch((err) => setError(err.message))
      .finally(() => setLoading(false))
  }, [])

  return (
    <div className="panel">
      <div className="hero">
        <h1>需求池</h1>
        <p>展示各项目的结构化需求池，支持阅读当前系统中已经抽取的需求条目。</p>
      </div>

      {error && <div className="notice error">错误：{error}</div>}

      {loading ? (
        <p>加载中…</p>
      ) : (
        items.map((group) => (
          <div key={group.project_id} className="card">
            <h3>{group.project_name}</h3>
            <div className="grid">
              {group.requirements.map((item) => (
                <div key={item.scope} className="card card-sm">
                  <h4>{item.scope}</h4>
                  <p>{item.description}</p>
                  <p className="tag">优先级：{item.priority}</p>
                  <ul>
                    {item.acceptance_criteria.map((criteria, idx) => (
                      <li key={idx}>{criteria}</li>
                    ))}
                  </ul>
                </div>
              ))}
            </div>
          </div>
        ))
      )}
    </div>
  )
}
