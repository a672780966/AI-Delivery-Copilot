'use client'

import { useEffect, useState } from 'react'

const backendUrl = process.env.NEXT_PUBLIC_BACKEND_URL || 'http://localhost:8000'

type RiskItem = {
  risk: string
  impact: string
  mitigation: string
}

type RiskSnapshot = {
  project_id: number
  project_name: string
  risks: RiskItem[]
}

export default function RiskPage() {
  const [snapshots, setSnapshots] = useState<RiskSnapshot[]>([])
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    setLoading(true)
    fetch(`${backendUrl}/api/v1/risk-snapshots`)
      .then((res) => res.json())
      .then((data) => setSnapshots(data))
      .catch((err) => setError(err.message))
      .finally(() => setLoading(false))
  }, [])

  return (
    <div className="panel">
      <div className="hero">
        <h1>风险雷达</h1>
        <p>展示当前项目的风险快照与缓解建议，帮助交付团队提前识别关键风险点。</p>
      </div>

      {error && <div className="notice error">错误：{error}</div>}

      {loading ? (
        <p>加载中…</p>
      ) : (
        <div className="grid">
          {snapshots.map((item) => (
            <div key={item.project_id} className="card">
              <h3>{item.project_name}</h3>
              <div className="item-block">
                {item.risks.map((risk, index) => (
                  <div key={index}>
                    <p><strong>风险：</strong>{risk.risk}</p>
                    <p><strong>影响：</strong>{risk.impact}</p>
                    <p><strong>缓解：</strong>{risk.mitigation}</p>
                  </div>
                ))}
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  )
}
