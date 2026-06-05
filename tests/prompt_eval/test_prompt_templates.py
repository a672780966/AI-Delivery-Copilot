from pathlib import Path


def test_prompt_templates_exist():
    base = Path(__file__).resolve().parents[2] / 'contracts' / 'prompts'
    assert base.exists(), 'prompt 模板目录未找到'
    templates = [
        'extract_requirements.md',
        'generate_artifacts.md',
    ]
    for template in templates:
        assert (base / template).exists(), f'{template} 缺失'
