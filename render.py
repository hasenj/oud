import jinja2
loader = jinja2.FileSystemLoader('templates')
env = jinja2.Environment(loader=loader)
t = env.get_template('index.html')
print t.render().encode('utf-8')
