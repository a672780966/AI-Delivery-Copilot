'use client'

import { useState } from 'react'

const backendUrl = process.env.NEXT_PUBLIC_BACKEND_URL || 'http://localhost:8000'

type RequirementItem = {
  scope: string
  description: string
  priority: 'low' | 'medium' | 'high'
  acceptance_criteria: string[]
}

type RequirementPool = {
  requirements: RequirementItem[]
  project_summary: string
}

type RequirementPoolResponse = {
  record_id: number
  pool: RequirementPool
  project_id?: number
}

type PRDItem = {
  title: string
  description: string
  acceptance_criteria: string[]
  priority: string
}

type UserStory = {
  as_a: string
  i_want: string
  so_that: string
  acceptance_criteria: string[]
}

type RiskItem = {
  risk: string
  impact: string
  mitigation: string
}

type KnowledgeEntry = {
  title: string
  source: string
  excerpt: string
}

type RetrospectiveEntry = {
  lesson: string
  category: 'success' | 'challenge' | 'improvement'
}

type ProjectArtifactsResponse = {
  record_id: number
  prd: PRDItem[]
  user_stories: UserStory[]
  risk_radar: RiskItem[]
  knowledge_base: KnowledgeEntry[]
  retrospective: RetrospectiveEntry[]
}

export default function Home() {
  const [transcript, setTranscript] = useState('')
  const [requirementSummary, setRequirementSummary] = useState('')
  const [requirementPool, setRequirementPool] = useState<RequirementPool | null>(null)
  const [projectId, setProjectId] = useState<number | null>(null)
  const [artifacts, setArtifacts] = useState<ProjectArtifactsResponse | null>(null)
  const [error, setError] = useState<string | null>(null)
  const [loading, setLoading] = useState(false)

  async function handleImport() {
    setError(null)
    setLoading(true)
    setArtifacts(null)
    try {
      const response = await fetch(`${backendUrl}/api/v1/import-notes`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          tenant_id: 'demo-tenant',
          user_id: 'demo-user',
          request_id: `req-${Date.now()}`,
          idempotency_key: `id-${Date.now()}`,
          transcript,
          project_name: 'Demo 项目',
          project_type: 'CRM',
        }),
      })
      const data: RequirementPoolResponse = await response.json()
      if (!response.ok) {
        throw new Error((data as any).detail || '导入失败，请检查后端服务是否可用')
      }
      setRequirementPool(data.pool)
      setRequirementSummary(data.pool.project_summary)
      setProjectId(data.project_id ?? null)
    } catch (err) {
      setError((err as Error).message)
    } finally {
      setLoading(false)
    }
  }

  async function handleGenerate() {
    setError(null)
    setLoading(true)
    try {
      const body = {
        tenant_id: 'demo-tenant',
        user_id: 'demo-user',
        request_id: `req-${Date.now()}`,
        idempotency_key: `art-${Date.now()}`,
        requirement_summary: requirementSummary,
        project_id: projectId,
      }
      const response = await fetch(`${backendUrl}/api/v1/generate-artifacts`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(body),
      })
      const data: ProjectArtifactsResponse = await response.json()
      if (!response.ok) {
        throw new Error((data as any).detail || '生成失败，请检查后端服务是否可用')
      }
      setArtifacts(data)
    } catch (err) {
      setError((err as Error).message)
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="panel">
      <div className="hero">
        <h1>AI Delivery Copilot</h1>
        <p>快速实现访谈文本导入、结构化需求抽取、需求池展示、PRD / 用户故事 / 风险雷达与复盘生成。</p>
      </div>

      <section className="section">
        <h2>1. 导入访谈文本</h2>
        <textarea
          rows={8}
          value={transcript}
          onChange={(e) => setTranscript(e.target.value)}
          placeholder="在此输入访谈内容，例如：客户希望CRM支持客户画像标签管理，并自动同步订单数据。"
        />
        <button onClick={handleImport} disabled={!transcript.trim() || loading}>
          {loading ? '提取中…' : '提取结构化需求'}
        </button>
      </section>

      {requirementPool && (
        <section className="section">
          <h2>2. 需求池</h2>
          <div className="card">
            <p className="summary">{requirementPool.project_summary}</p>
            <div className="grid">
              {requirementPool.requirements.map((item) => (
                <div key={item.scope} className="card card-sm">
                  <h3>{item.scope}</h3>
                  <p>{item.description}</p>
                  <p className="tag">优先级：{item.priority}</p>
                  <ul>
                    {item.acceptance_criteria.map((criteria, index) => (
                      <li key={index}>{criteria}</li>
                    ))}
                  </ul>
                </div>
              ))}
            </div>
          </div>
          <button onClick={handleGenerate} disabled={!requirementSummary || loading}>
            {loading ? '生成中…' : '生成项目交付文档'}
          </button>
        </section>
      )}

      {artifacts && (
        <section className="section">
          <h2>3. 生成结果</h2>
          <div className="grid">
            <div className="card">
              <h3>PRD</h3>
              {artifacts.prd.map((item, index) => (
                <div key={index} className="item-block">
                  <strong>{item.title}</strong>
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

            <div className="card">
              <h3>用户故事</h3>
              {artifacts.user_stories.map((item, index) => (
                <div key={index} className="item-block">
                  <p><strong>作为：</strong>{item.as_a}</p>
                  <p><strong>我希望：</strong>{item.i_want}</p>
                  <p><strong>从而：</strong>{item.so_that}</p>
                  <ul>
                    {item.acceptance_criteria.map((criteria, idx) => (
                      <li key={idx}>{criteria}</li>
                    ))}
                  </ul>
                </div>
              ))}
            </div>
          </div>

          <div className="grid">
            <div className="card">
              <h3>风险雷达</h3>
              {artifacts.risk_radar.map((item, index) => (
                <div key={index} className="item-block">
                  <p><strong>风险：</strong>{item.risk}</p>
                  <p><strong>影响：</strong>{item.impact}</p>
                  <p><strong>缓解：</strong>{item.mitigation}</p>
                </div>
              ))}
            </div>

            <div className="card">
              <h3>知识库 & 复盘</h3>
              {artifacts.knowledge_base.map((item, index) => (
                <div key={index} className="item-block">
                  <p><strong>{item.title}</strong>（{item.source}）</p>
                  <p>{item.excerpt}</p>
                </div>
              ))}
              {artifacts.retrospective.map((item, index) => (
                <div key={index} className="item-block">
                  <p>{item.lesson}</p>
                  <p className="tag">类别：{item.category}</p>
                </div>
              ))}
            </div>
          </div>
        </section>
      )}

      {error && <div className="notice error">错误：{error}</div>}
    </div>
  )
}
