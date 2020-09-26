
require_relative '../delta-simplecov-checks/checks'

Handler = Proc.new do |req, res|
  if req.method != 'POST'
    res.status = 400
    res['Content-Type'] = 'text/text; charset=utf-8'
    res.body = "Bad request"
  else
    req_body = JSON.parse(req.body)
    DeltaSimplecovChecks.new(nil).post_check(req_body['repository'], req_body['body'])
    res.status = 200
    res['Content-Type'] = 'text/text; charset=utf-8'
    res.body = "Checks updated"
  end
end

