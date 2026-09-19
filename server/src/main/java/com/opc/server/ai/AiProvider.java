package com.opc.server.ai;

/**
 * AI 服务商抽象接口 —— <b>本项目 MCP 思想的核心。</b>
 *
 * <p>完整的 MCP（Model Context Protocol）协议不在课设范围内，
 * 但它的架构价值在这里被完整保留：<b>把「调用哪个模型」从业务代码里抽出来</b>。
 *
 * <h3>三个解耦点</h3>
 * <ol>
 *   <li><b>接口解耦</b>：{@code HarnessScheduler} 只依赖本接口，
 *       不认识任何具体服务商。新增服务商 = 新增一个实现类，调度代码一行不动。</li>
 *   <li><b>配置解耦</b>：选哪个服务商由 {@code t_skill.provider} 字段决定，
 *       <b>改数据库就能切换，不用改代码、不用重新打包</b>。</li>
 *   <li><b>参数解耦</b>：统一走 {@link AiTaskRequest}，
 *       各实现类内部自己做参数翻译，调用方不需要为每个服务商写不同逻辑。</li>
 * </ol>
 *
 * <h3>实现类需要做的最小集合</h3>
 * <p>只实现 {@link #getName()} 和 {@link #submit} 就能跑通整条链路。
 * {@link #query} 与 {@link #cancel} 是为异步服务商预留的
 * （提交后返回任务 ID，之后轮询查进度），Mock 用不到所以给了默认实现。
 */
public interface AiProvider {

    /**
     * 服务商标识，必须与 {@code t_skill.provider} 里存的值一致。
     *
     * @see ProviderNames
     */
    String getName();

    /**
     * 提交生成任务。
     *
     * <p><b>同步实现</b>（如 Mock）：阻塞到出图，直接返回带 resultUrl 的结果。
     * <b>异步实现</b>：只负责提交，返回带 providerTaskId 的结果，
     * 之后由 Harness 调 {@link #query} 回查。
     *
     * @param request  统一请求参数
     * @param listener 进度回调，实现类应定期调用它上报 0-100
     * @return 生成结果，失败时用 {@link AiTaskResult#fail(String)} 而不是抛异常 ——
     *         服务商超时、限流属于正常业务失败，Harness 要把它记成任务失败并允许重试，
     *         不能让它变成一个未捕获异常。
     */
    AiTaskResult submit(AiTaskRequest request, ProgressListener listener);

    /**
     * 回查异步任务进度。同步服务商不需要实现。
     *
     * @param providerTaskId {@link #submit} 返回的服务商侧任务 ID
     */
    default AiTaskResult query(String providerTaskId) {
        return AiTaskResult.fail("服务商 " + getName() + " 不支持异步回查");
    }

    /**
     * 取消服务商侧的异步任务。
     *
     * @return 是否成功取消；不支持取消的实现返回 false
     */
    default boolean cancel(String providerTaskId) {
        return false;
    }

    /**
     * 服务商当前是否可用（密钥是否配置、额度是否耗尽等）。
     *
     * <p>Harness 在路由失败时会跳过不可用的服务商。默认可用，
     * 真实实现类应该检查自己的密钥配置。
     */
    default boolean isAvailable() {
        return true;
    }
}
