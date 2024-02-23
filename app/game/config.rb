def default_config args
  args.state.config ||= {
    lights: true,
    particles: true,
    language: :eng,
  }
end
