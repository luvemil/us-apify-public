IMAGE_TAG=latest

all:
	rm -rf lib/us-lib-private
	@git clone git@github.com:luvemil/us-lib-private.git lib/us-lib-private -n
	cd lib/us-lib-private && git checkout ae85ad792a670585fb5246329f6865c380353eef
	@docker build . -t ${IMAGE_NAME}:${IMAGE_TAG}
	rm -rf lib/us-lib-private

run-local:
	@docker run --env-file .runenv --rm -p 9000:8080 ${IMAGE_NAME}:${IMAGE_TAG}

publish:
	@docker tag ${IMAGE_NAME}:${IMAGE_TAG} ${REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}
	@docker push ${REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}
	@docker rmi ${REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}