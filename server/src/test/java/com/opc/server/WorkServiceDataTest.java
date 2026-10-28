package com.opc.server;

import com.opc.server.entity.Work;
import com.opc.server.entity.enums.WorkType;
import com.opc.server.repository.SkillRepository;
import com.opc.server.repository.WorkRepository;
import com.opc.server.service.WorkService;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.data.jpa.test.autoconfigure.DataJpaTest;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * 回归测试：作品未绑定 Skill 时，列表接口仍应正常返回。
 */
@DataJpaTest
class WorkServiceDataTest {

    @Autowired
    private WorkRepository workRepository;

    @Autowired
    private SkillRepository skillRepository;

    @Test
    void listsWorkWhenSkillIdIsNull() {
        workRepository.save(Work.builder()
                .userId(1L)
                .taskId(1L)
                .title("未绑定线路的作品")
                .type(WorkType.IMAGE)
                .resourceUrl("/upload/test.png")
                .prompt("test prompt")
                .skillId(null)
                .isPublic(false)
                .likeCount(0)
                .viewCount(0)
                .deleted(false)
                .build());

        WorkService service = new WorkService(workRepository, skillRepository);
        var responses = service.listMyWorks(1L, 1, 20, null);

        assertThat(responses).hasSize(1);
        assertThat(responses.getFirst().skillName()).isNull();
    }
}
