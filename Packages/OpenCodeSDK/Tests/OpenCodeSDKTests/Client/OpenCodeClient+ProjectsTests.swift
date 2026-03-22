import Foundation
import OpenCodeSDK
import Testing

struct OpenCodeClientProjectsTests {
  @Test func projectRoutes() async throws {
    let controller = makeSuccessPathController()
    let client = makeClient(controller: controller)

    let projects = try await client.listProjects()
    #expect(projects.first?.id == "prj_1")

    let currentProject = try await client.getCurrentProject()
    #expect(currentProject.id == "prj_current")
    #expect(currentProject.commands?.start == "bun dev")

    let initializedProjectGit = try await client.initializeProjectGit()
    #expect(initializedProjectGit.id == "prj_git")
    #expect(initializedProjectGit.vcs == "git")
    #expect(initializedProjectGit.time.initialized == 4)

    let updatedProject = try await client.updateProject(
      id: "prj_1",
      body: ProjectUpdateRequest(name: "Renamed", icon: ProjectIcon(url: nil, override: "bolt", color: "blue"), commands: ProjectCommands(start: "npm start"))
    )
    #expect(updatedProject.name == "Renamed")
    #expect(updatedProject.icon?.override == "bolt")

    let requests = controller.recordedRequests
    #expect(requests.contains { $0.url?.path == "/project" && $0.httpMethod == "GET" })
    #expect(requests.contains { $0.url?.path == "/project/current" && $0.url?.query?.contains("directory=/tmp/default") == true })
    #expect(requests.contains { $0.url?.path == "/project/git/init" && $0.httpMethod == "POST" })
    #expect(requests.contains { $0.url?.path == "/project/prj_1" && $0.httpMethod == "PATCH" })
  }
}
