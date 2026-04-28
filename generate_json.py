import json
import os

# 构建我们自己的带中文和音标的 AWL 数据
awl_data = [
  {
    "title": "Sublist 1",
    "words": [
      {"id": 1, "english": "analyze", "phonetic": "/ˈæn.ə.laɪz/", "chinese": "v. 分析", "example": "We need to analyze the data."},
      {"id": 2, "english": "approach", "phonetic": "/əˈprəʊtʃ/", "chinese": "n. 方法; v. 接近", "example": "A new approach to the problem."},
      {"id": 3, "english": "area", "phonetic": "/ˈeə.ri.ə/", "chinese": "n. 区域; 领域", "example": "This is a quiet area."},
      {"id": 4, "english": "assess", "phonetic": "/əˈses/", "chinese": "v. 评估，评定", "example": "They assessed the cost of the flood damage."},
      {"id": 5, "english": "assume", "phonetic": "/əˈsjuːm/", "chinese": "v. 假设，假定", "example": "I assume that you know each other."},
      {"id": 6, "english": "authority", "phonetic": "/ɔːˈθɒr.ə.ti/", "chinese": "n. 权力，官方", "example": "He has the authority to make decisions."},
      {"id": 7, "english": "available", "phonetic": "/əˈveɪ.lə.bəl/", "chinese": "adj. 可获得的，可用的", "example": "Is this dress available in a larger size?"},
      {"id": 8, "english": "benefit", "phonetic": "/ˈben.ɪ.fɪt/", "chinese": "n. 利益，好处", "example": "The discovery is of great benefit to humanity."},
      {"id": 9, "english": "concept", "phonetic": "/ˈkɒn.sept/", "chinese": "n. 概念，观念", "example": "He introduced a new concept."},
      {"id": 10, "english": "consist", "phonetic": "/kənˈsɪst/", "chinese": "v. 组成，构成", "example": "The committee consists of ten members."},
      {"id": 11, "english": "constitute", "phonetic": "/kənˈstɪt.juːt/", "chinese": "v. 构成，组成", "example": "Women constitute about 10% of Parliament."},
      {"id": 12, "english": "context", "phonetic": "/ˈkɒn.tekst/", "chinese": "n. 环境，上下文", "example": "In this context, the word means something else."},
      {"id": 13, "english": "contract", "phonetic": "/ˈkɒn.trækt/", "chinese": "n. 合同，契约", "example": "They signed a contract."},
      {"id": 14, "english": "create", "phonetic": "/kriˈeɪt/", "chinese": "v. 创造，创建", "example": "The software creates a virtual environment."},
      {"id": 15, "english": "data", "phonetic": "/ˈdeɪ.tə/", "chinese": "n. 数据，资料", "example": "The data was collected by various researchers."},
      {"id": 16, "english": "define", "phonetic": "/dɪˈfaɪn/", "chinese": "v. 定义", "example": "Define the word 'happy'."},
      {"id": 17, "english": "derive", "phonetic": "/dɪˈraɪv/", "chinese": "v. 获得，源于", "example": "The word derives from Latin."},
      {"id": 18, "english": "distribute", "phonetic": "/dɪˈstrɪb.juːt/", "chinese": "v. 分发，分配", "example": "The books will be distributed free."},
      {"id": 19, "english": "economy", "phonetic": "/ɪˈkɒn.ə.mi/", "chinese": "n. 经济", "example": "The global economy is growing."},
      {"id": 20, "english": "environment", "phonetic": "/ɪnˈvaɪ.rən.mənt/", "chinese": "n. 环境", "example": "We must protect the environment."},
      {"id": 21, "english": "establish", "phonetic": "/ɪˈstæb.lɪʃ/", "chinese": "v. 建立，设立", "example": "The company was established in 1822."},
      {"id": 22, "english": "estimate", "phonetic": "/ˈes.tɪ.meɪt/", "chinese": "v. 估计，估算", "example": "They estimate that the journey will take two hours."},
      {"id": 23, "english": "evident", "phonetic": "/ˈev.ɪ.dənt/", "chinese": "adj. 明显的，明白的", "example": "It is evident that you are tired."},
      {"id": 24, "english": "export", "phonetic": "/ɪkˈspɔːt/", "chinese": "v. 出口", "example": "French cheeses are exported to many different countries."},
      {"id": 25, "english": "factor", "phonetic": "/ˈfæk.tər/", "chinese": "n. 因素，要素", "example": "Price is an important factor."}
    ]
  },
  {
    "title": "Sublist 2",
    "words": [
      {"id": 26, "english": "achieve", "phonetic": "/əˈtʃiːv/", "chinese": "v. 实现，达到", "example": "She finally achieved her ambition."},
      {"id": 27, "english": "acquire", "phonetic": "/əˈkwaɪər/", "chinese": "v. 获得，取得", "example": "He has acquired a reputation as a difficult boss."},
      {"id": 28, "english": "administer", "phonetic": "/ədˈmɪn.ɪ.stər/", "chinese": "v. 管理，执行", "example": "The fund is administered by the Economic and Social Research Council."},
      {"id": 29, "english": "affect", "phonetic": "/əˈfekt/", "chinese": "v. 影响", "example": "Both buildings were badly affected by the fire."},
      {"id": 30, "english": "appropriate", "phonetic": "/əˈprəʊ.pri.ət/", "chinese": "adj. 适当的，恰当的", "example": "Is this film appropriate for small children?"}
    ]
  }
]

os.makedirs('assets', exist_ok=True)
with open('assets/words.json', 'w', encoding='utf-8') as f:
    json.dump(awl_data, f, ensure_ascii=False, indent=2)

print('JSON generated successfully!')
