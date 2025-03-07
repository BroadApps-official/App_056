import SwiftUI

struct Instruction: Identifiable {
  let id = UUID()
  let imageName: String
  let text: String
}

struct ImageUrl: Identifiable, Hashable {
  let url: String
  var id: String { url }
}

struct PresetsResponse: Codable {
  let error: Bool
  let message: String?
  let data: [PresetCategory]
}

struct PresetCategory: Codable, Identifiable {
  let id: Int
  let title: String
  let preview: String?
  let isNew: Bool
  let templates: [PresetTemplate]
}

struct PresetTemplate: Codable, Identifiable {
  let id: Int
  let title: String?
  let preview: String
  let gender: String
  let isEnabled: Bool
}

struct AvatarListResponse: Codable {
  let error: Bool
  let message: String?
  let data: [Avatar]
}

struct UploadAvatarResponse: Codable {
  let id: Int
  let status: String
  let jobId: String
  let avatar: String? 
  let createdAt: String
}

struct AvatarStatusResponse: Codable {
  let id: Int
  let status: String
  let jobId: String
  let avatar: Avatar?
  let createdAt: String
}

struct AddAvatarResponse: Codable {
  let error: Bool
  let message: String?
  let data: AvatarData?
  let avatars: [AvatarData]?
}

struct AvatarResponse: Codable {
  let error: Bool
  let message: String?
  let data: AvatarData?
}

struct AvatarData: Codable {
  let id: Int
  let status: String
  let jobId: String
  let avatar: Avatar?
  let createdAt: String
}

struct Avatar: Codable, Identifiable {
  let id: Int
  let title: String?
  var preview: String?
  let gender: String
  let isActive: Bool
}

struct GenerationResponse: Decodable {
  let error: Bool
  let message: String?
  let data: GenerationData?
}

struct GenerationStatusResponse: Decodable {
  let error: Bool
  let message: String?
  let data: GenerationStatusData
}

struct GenerationStatusData: Decodable {
  let id: Int
  let generationId: Int
  let jobId: String
  let status: String
  let preview: String?
  let resultUrl: String?
}

struct GenerationData: Decodable {
  let id: Int
  let generationId: Int
  let jobId: String
  let isGodMode: Bool
  let templateId: Int?
  let preview: String?
  let resultUrl: String?
  let status: String
  let startedAt: String
  let finishedAt: String?
  let isCoupled: Bool?
  let isTxt2Img: Bool?
  let isMarked: Bool?
  let mark: String?
  let seconds: Int?
  let isCouple: Bool?
  
  enum CodingKeys: String, CodingKey {
    case id, generationId, jobId, status, preview, resultUrl, isCoupled, isTxt2Img, isMarked, mark, seconds, startedAt, finishedAt, templateId, isCouple
  }
  
  init(
    id: Int,
    generationId: Int,
    jobId: String,
    isGodMode: Bool,
    templateId: Int?,
    preview: String?,
    resultUrl: String?,
    status: String,
    startedAt: String,
    finishedAt: String?,
    isCoupled: Bool? = nil,
    isTxt2Img: Bool? = nil,
    isMarked: Bool? = nil,
    mark: String? = nil,
    seconds: Int? = nil,
    isCouple: Bool? = nil
  ) {
    self.id = id
    self.jobId = jobId
    self.isGodMode = isGodMode
    self.templateId = templateId
    self.preview = preview
    self.resultUrl = resultUrl
    self.status = status
    self.startedAt = startedAt
    self.finishedAt = finishedAt
    self.isCoupled = nil
    self.isTxt2Img = nil
    self.isMarked = nil
    self.mark = nil
    self.seconds = seconds
    self.isCouple = nil
    self.generationId = generationId
  }
  
  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    
    id = try container.decode(Int.self, forKey: .id)
    generationId = try container.decode(Int.self, forKey: .generationId)
    jobId = try container.decode(String.self, forKey: .jobId)
    status = try container.decode(String.self, forKey: .status)
    preview = try container.decodeIfPresent(String.self, forKey: .preview)
    resultUrl = try container.decodeIfPresent(String.self, forKey: .resultUrl)
    startedAt = try container.decode(String.self, forKey: .startedAt)
    finishedAt = try container.decodeIfPresent(String.self, forKey: .finishedAt)
    templateId = try container.decodeIfPresent(Int.self, forKey: .templateId)
    isCoupled = try container.decodeIfPresent(Bool.self, forKey: .isCoupled)
    isTxt2Img = try container.decodeIfPresent(Bool.self, forKey: .isTxt2Img)
    isMarked = try container.decodeIfPresent(Bool.self, forKey: .isMarked)
    mark = try container.decodeIfPresent(String.self, forKey: .mark)
    seconds = try container.decodeIfPresent(Int.self, forKey: .seconds)
    isCouple = try container.decodeIfPresent(Bool.self, forKey: .isCouple)
    isGodMode = isCouple ?? false
  }
}
