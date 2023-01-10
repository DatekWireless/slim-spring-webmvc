class PartialRequest < javax.servlet.http.HttpServletRequestWrapper
  def initialize(request, partialParams)
    super(request)

    @params = request.getParameterMap().to_h.merge(partialParams)
  end
end
