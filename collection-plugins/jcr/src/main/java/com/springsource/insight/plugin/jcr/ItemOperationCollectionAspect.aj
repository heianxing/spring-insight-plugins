/**
 * Copyright (c) 2009-2011 VMware, Inc. All Rights Reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *         http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package com.springsource.insight.plugin.jcr;

import javax.jcr.Item;
import javax.jcr.Node;
import javax.jcr.RepositoryException;

import org.aspectj.lang.JoinPoint;

import com.springsource.insight.collection.AbstractOperationCollectionAspect;
import com.springsource.insight.intercept.operation.Operation;


/**
 * This aspect intercepts all JCR Item requests for: save, refresh, remove, update and addNode
 */
public privileged aspect ItemOperationCollectionAspect extends AbstractOperationCollectionAspect {
    public ItemOperationCollectionAspect() {
        super();
    }

    public pointcut itemRemove(): execution(public void javax.jcr.Item+.remove());
    public pointcut nodeUpdate(): execution(public void javax.jcr.Node+.update(String));
    public pointcut nodeAdd(): execution(public Node javax.jcr.Node+.addNode(..));

    public pointcut collectionPoint(): itemRemove() || nodeUpdate() || nodeAdd();

    @Override
    protected Operation createOperation(JoinPoint jp) {
        Item item = (Item) jp.getTarget();
        String path = null;
        try {
            path = item.getPath(); //relating item path
        } catch (RepositoryException e) {
            //ignore
        }

        String method = jp.getSignature().getName();
        Operation op = new Operation().type(OperationCollectionTypes.ITEM_TYPE.type)
                .label(OperationCollectionTypes.ITEM_TYPE.label + " " + method + " [" + path + "]")
                .sourceCodeLocation(getSourceCodeLocation(jp))
                .putAnyNonEmpty("workspace", JCRCollectionUtils.getWorkspaceName(item))
                .putAnyNonEmpty("path", path);

        //add request parameters
        Object[] args = jp.getArgs();
        if (method.equals("update")) {
            op.putAnyNonEmpty("srcWorkspace", args[0]);
        } else if (method.equals("addNode")) {
            op.putAnyNonEmpty("relPath", args[0]);
        }

        return op;
    }

    @Override
    public String getPluginName() {
        return JCRPluginRuntimeDescriptor.PLUGIN_NAME;
    }
}